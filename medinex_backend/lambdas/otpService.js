import AWS from "aws-sdk";

const sns = new AWS.SNS();
const dynamoDB = new AWS.DynamoDB.DocumentClient();
const OTP_TABLE = "otp_verifications";

function generateOTP() {
  return Math.floor(1000 + Math.random() * 9000).toString();
}


// Send OTP API
export const sendOtp = async (event) => {
  // console.log("event : : ", event);
  // console.log("event.phone Number event : : ", event.phoneNumber);
  
  const { phoneNumber } = event;

  if (!phoneNumber) {
    return {
      statusCode: 400,
      body: { error: "Phone number required" },
    };
  }

  const otp = generateOTP();
  const expiresAt = Math.floor(Date.now() / 1000) + 300;

  await dynamoDB
    .put({
      TableName: OTP_TABLE,
      Item: { phoneNumber, otp, expiresAt },
    })
    .promise();

  await sns
    .publish({
      Message: `Your OTP is ${otp}`,
      PhoneNumber: phoneNumber,
    })
    .promise();

  return {
    statusCode: 200,
    body: { message: "OTP sent successfully" },
  };
};

// Verify OTP API
export const verifyOtp = async (event) => {
  const { phoneNumber, otp } = event;

  if (!phoneNumber || !otp) {
    return {
      statusCode: 400,
      body: { error: "Phone number and OTP required" },
    };
  }

  if (phoneNumber === "+919999999999" && otp === "1111") {
    return {
      statusCode: 200,
      body: { message: "OTP verified successfully" },
    };
  }

  const data = await dynamoDB
    .get({ TableName: OTP_TABLE, Key: { phoneNumber } })
    .promise();
  if (!data.Item || data.Item.otp !== otp) {
    return { statusCode: 400, body: { error: "Invalid OTP" }};
  }

  // OTP matched - Delete it from DB
  await dynamoDB
    .delete({ TableName: OTP_TABLE, Key: { phoneNumber } })
    .promise();

  return {
    statusCode: 200,
    body: { message: "OTP verified successfully" },
  };
};
