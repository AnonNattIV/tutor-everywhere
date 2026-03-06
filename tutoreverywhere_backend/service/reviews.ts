import express from "express"
import bodyParser from "body-parser";
import { addReview, getReviewByTutorId } from "../controllers/reviews.ts";
import { verifyToken } from "../middleware/verify.ts";

const reviewService = express.Router();

reviewService.use(bodyParser.json());
reviewService.get("/:tutorId", async (req, res) => {
  const params = req.params;
  const tutorId = params.tutorId;
  try {
    const reviews = await getReviewByTutorId(tutorId);
    res.status(200).json(reviews);
  } catch {
    res.status(500).json({ error: "Review Service Error" });
  }
});

reviewService.post("/", verifyToken, async (req, res) => {
  try {
    const authData = req.body.authData;
    const reviewerRole = authData.role;
    const reviewerUserId = authData.userId;
    const revieweeUserId = req.body.reviewee;
    const rating = req.body.rating;
    const comment = req.body.comment;
    const subject = req.body.subject;

    if (reviewerRole != "student") throw new Error(`This user ${reviewerUserId} is not a student`);
    await addReview(reviewerUserId, revieweeUserId, rating, subject, comment);
    res.status(200).json({ message: "Sucessfully added review" })
  } catch {
    res.status(500).json({ error: "Review Service Error" });
  }
});

export default reviewService