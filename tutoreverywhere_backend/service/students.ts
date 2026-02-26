import express from "express"
import bodyParser from "body-parser";
import { viewStudentData, updateStudentBio } from "../controllers/students.ts";
import { verifyToken } from "../middleware/verify.ts";

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

export default studentService