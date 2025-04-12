import { sendOtp, verifyOtp } from "./otpService.js";
import { registerPatient } from "./registerPatient.js";
import { registerDoctor } from "./registerDoctor.js";
import { loginPatient } from "./loginPatient.js";
import { setDoctorPassword } from "./setDoctorPassword.js";
import { loginDoctor } from "./loginDoctor.js";
import { getDoctorDetailsByLoginId } from "./getDoctorDetails.js";
import { getPatientDetailsByNumber } from "./getPatientDetails.js";
import { createAppointment } from "./addAppointment.js";
import { getAppointmentsByPatientId } from "./getAppointmentPatient.js";
import { getAppointmentsByDoctorId } from "./getAppointmentDoctor.js";
import { cancelAppointment } from "./cancelAppointment.js";
import { getApprovedDoctors } from "./getVerifiedDoctors.js";
import { getAvailableSlots } from "./appointmentsByDoctorIdDate.js";

export const sendOTP = sendOtp;
export const verifyOTP = verifyOtp;
export const addPatient = registerPatient;
export const addDoctor = registerDoctor;
export const patientLogin = loginPatient;
export const createDoctorPassword = setDoctorPassword;
export const doctorLogin = loginDoctor;
export const getDoctorDetails = getDoctorDetailsByLoginId;
export const getPatientDetails = getPatientDetailsByNumber;
export const addAppointment = createAppointment;
export const getAppointmentPatient = getAppointmentsByPatientId;
export const getAppointmentDoctor = getAppointmentsByDoctorId;
export const deleteAppointment = cancelAppointment;
export const getVerifiedDoctors = getApprovedDoctors;
export const getAppointmentsByDoctorIdAndDate = getAvailableSlots;
