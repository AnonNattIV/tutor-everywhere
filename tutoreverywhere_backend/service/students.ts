import express from "express"
import bodyParser from "body-parser";
import { viewStudentData } from "../controllers/students.ts";
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
  console.log(req.body);
})

export default studentService