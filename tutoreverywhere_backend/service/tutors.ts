import express from "express"
import bodyParser from "body-parser";
import { getTutorSubjects, updateTutorBio, updateTutorPreferredPlace, viewTutorData } from "../controllers/tutors.ts";
import { verifyToken } from "../middleware/verify.ts";

const tutorService = express.Router();

tutorService.use(bodyParser.json());
tutorService.get("/profile/:userId", async (req, res) => {
  const params = req.params;
  const userId = params.userId;
  try {
    const tutorData = await viewTutorData(userId);
    res.status(200).json(tutorData[0]);
  } catch (err) {
    res.status(404).json({message: "Account not found"});
  }
})

tutorService.post("/bio", verifyToken, async (req, res) => {
  const authData = req.body.authData;
  const userId = authData.userId;
  const role = authData.role;
  const bio = req.body.bio;
  try {
    if (role != "tutor") throw new Error(`This user ${userId} is not a tutor`);
    await updateTutorBio(userId, bio)
    res.status(200).json({message: "Successfully updated bio"});
  } catch (err) {
    res.status(500).json({message: "Error bio"});
  }
})

tutorService.post("/preferredPlace", verifyToken, async (req, res) => {
  const authData = req.body.authData;
  const userId = authData.userId;
  const role = authData.role;
  const preferred_place = req.body.preferred_place;
  try {
    if (role != "tutor") throw new Error(`This user ${userId} is not a tutor`);
    await updateTutorPreferredPlace(userId, preferred_place)
    res.status(200).json({message: "Successfully updated preferred place"});
  } catch (err) {
    res.status(500).json({message: "Error bio"});
  }
})

tutorService.get("/subjects/:userId", async (req, res) => {
  const params = req.params;
  const userId = params.userId;
  try {
    const tutorSubjects = await getTutorSubjects(userId);
    res.status(200).json(tutorSubjects);
  } catch (err) {
    res.status(404).json({message: "Account not found"});
  }
})

export default tutorService