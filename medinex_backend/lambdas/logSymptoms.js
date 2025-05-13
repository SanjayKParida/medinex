import { getMongoClient } from "../db/db.js";

let mongoClient;

// Function to clean the Gemini response text
function cleanGeminiResponse(text) {
  // Remove markdown formatting
  let cleaned = text
    .replace(/\*\*/g, "") // Remove bold
    .replace(/\*/g, "") // Remove italics
    .replace(/\n\*/g, "\n") // Remove bullet points
    .replace(/\n\n/g, "\n") // Remove double newlines
    .replace(/```json/g, "") // Remove code block markers
    .replace(/```/g, "")
    .trim();

  // Remove any remaining special characters
  cleaned = cleaned.replace(/[^\w\s.,:;!?()\-]/g, " ");

  // Remove extra spaces
  cleaned = cleaned.replace(/\s+/g, " ");

  return cleaned;
}

export const handler = async (event, context) => {
  context.callbackWaitsForEmptyEventLoop = false;
  try {
    const { currentSymptoms, medicalHistory, notes, patientId } = event;

    // Validate inputs
    if (!currentSymptoms) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: "Missing symptoms",
          error: "SYMPTOMS_REQUIRED",
        }),
      };
    }

    if (!patientId) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: "Missing patient ID",
          error: "PATIENT_ID_REQUIRED",
        }),
      };
    }

    // If medicalHistory is null or missing, set it to an empty string
    const history = medicalHistory || "";

    // Connect to MongoDB
    mongoClient = await getMongoClient();

    // Check for previous logs
    const previousLogs = await mongoClient
      .db("medenix")
      .collection("healthLogs")
      .find({ patientId })
      .sort({ createdAt: -1 })
      .limit(5)
      .toArray();

    // Create the prompt for the model
    const prompt = `You are a medical assistant. A user has reported the following symptoms:\n\n${currentSymptoms}\n\nAnd their medical history is:\n${history}\n\nAdditional notes: ${
      notes || ""
    }\n\nPrevious symptoms (if any):\n${
      previousLogs.length > 0
        ? previousLogs
            .map(
              (log) =>
                `- ${log.currentSymptoms} (${new Date(
                  log.createdAt
                ).toLocaleDateString()})`
            )
            .join("\n")
        : "No previous symptoms recorded"
    }\n\nBased on this, provide the following:\n1. Possible Conditions (short and likely)\n2. Risk Level (if any, brief)\n3. Suggestions (like dietary/lifestyle)\n\nPlease reply in JSON format with keys: possible_conditions, risk_level, suggestions.`;

    // Prepare the request for Gemini API
    const geminiRequest = {
      contents: [
        {
          parts: [
            {
              text: prompt,
            },
          ],
        },
      ],
    };

    const response = await fetch(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=" +
        process.env.GEMINI_API_KEY,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(geminiRequest),
      }
    );

    if (!response.ok) {
      throw new Error(
        `Gemini API request failed with status ${response.status}`
      );
    }

    const result = await response.json();

    // Extract the generated text from Gemini's response
    const generatedText = result.candidates[0].content.parts[0].text;

    // Clean the generated text
    const cleanedText = cleanGeminiResponse(generatedText);

    // Create the log entry
    const logEntry = {
      patientId,
      currentSymptoms,
      medicalHistory: history,
      notes: notes || "",
      generatedInsights: cleanedText,
      createdAt: new Date().toISOString(),
    };

    // Insert the result into the database
    await mongoClient
      .db("medenix")
      .collection("healthLogs")
      .insertOne(logEntry);

    // Return the model insights and previous logs as a JSON response
    return {
      statusCode: 200,
      body: JSON.stringify({
        insights: cleanedText,
        previousLogs: previousLogs.map((log) => ({
          symptoms: log.currentSymptoms,
          date: log.createdAt,
          insights: log.generatedInsights,
        })),
      }),
    };
  } catch (err) {
    console.error("Error invoking model or saving to DB:", err);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: "Error generating insights or saving to DB",
        error: err.message,
      }),
    };
  }
};
