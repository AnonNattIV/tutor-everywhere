import express from "express"
import bodyParser from "body-parser";
import { viewTutorData } from "../controllers/tutors.ts";

const tutorService = express.Router();

tutorService.use(bodyParser.json());
tutorService.get("/:userId", async (req, res) => {
  const params = req.params;
  const userId = params.userId;
  try {
    const tutorData = await viewTutorData(userId);
    res.status(200).json(tutorData[0]);
  } catch (err) {
    res.status(404).json({message: "Account not found"});
  }
})

export default tutorService