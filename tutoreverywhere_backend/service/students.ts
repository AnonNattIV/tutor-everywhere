import express from "express"
import bodyParser from "body-parser";
import { viewStudentData, updateStudentBio, updateStudentProfilePicture } from "../controllers/students.ts";
import { verifyToken } from "../middleware/verify.ts";
import { upload } from "../middleware/multer.ts";
import { getAppointmentByStudentId } from "../controllers/appointments.ts";
import { uploadImageToObjectStorage } from "../helpers/objectStorage.ts";

const studentService = express.Router();

studentService.use(bodyParser.json());
studentService.get("/profile/:userId", async (req, res) => {
  const params = req.params;
  const userId = params.userId;
  try {
    const tutorData = await viewStudentData(userId);
    res.status(200).json(tutorData[0]);
  } catch (err) {
    res.status(404).json({message: "Account not found"});
  }
})

studentService.patch(
  "/profile-picture",
  verifyToken,
  (req: any, res: any, next: any) => {
    const authData = req.body.authData;
    upload.single('profilePicture')(req, res, (err) => {
      if (err) return res.status(400).json({ message: err.message });
      req.body.authData = authData;
      next();
    });
  },
  async (req: any, res: any) => {
    const { userId, role } = req.body.authData;

    try {
      if (role !== "student") {
        return res.status(403).json({ message: `This user ${userId} is not a student` });
      }

      if (!req.file) {
        return res.status(400).json({ message: "No file uploaded" });
      }

      const profilePicturePath = await uploadImageToObjectStorage(req.file, "pfp");
      await updateStudentProfilePicture(userId, profilePicturePath);

      res.status(200).json({
        message: "Successfully updated profile picture",
        profilePicture: profilePicturePath
      });
    } catch (err: any) {
      console.error("Error uploading profile picture", err);
      res
        .status(500)
        .json({ message: err?.message || "Error uploading profile picture" });
    }
  }
);

studentService.post("/bio", verifyToken, async (req, res) => {
  const authData = req.body.authData;
  const userId = authData.userId;
  const role = authData.role;
  const bio = req.body.bio;
  try {
    if (role != "student") throw new Error(`This user ${userId} is not a student`);
    await updateStudentBio(userId, bio)
    res.status(200).json({message: "Successfully updated bio"});
  } catch (err) {
    res.status(500).json({message: "Error bio"});
  }
})

studentService.get("/appointments/:userId", async (req, res) => {
  const query = req.query;
  const year = Number.parseInt(query.year?.toString() ?? "", 10);
  const month = Number.parseInt(query.month?.toString() ?? "", 10);
  const dayRaw = query.day?.toString();
  const day = dayRaw == null ? undefined : Number.parseInt(dayRaw, 10);
  const params = req.params;
  const userId = params.userId;

  if (Number.isNaN(year) || Number.isNaN(month)) {
    return res.status(400).json({ message: "year and month are required" });
  }
  if (month < 1 || month > 12) {
    return res.status(400).json({ message: "month must be 1-12" });
  }
  if (dayRaw != null && (Number.isNaN(day) || day! < 1 || day! > 31)) {
    return res.status(400).json({ message: "day must be 1-31" });
  }

  try {
    const appointments = await getAppointmentByStudentId(userId, {
      year,
      month,
      day,
    })
    res.status(200).json(appointments);
  } catch (err) {
    res.status(500).json({message: "Error find student appointment" });
  }
})

export default studentService
