import sql from "../db/db.ts";

async function addReview(reviewerUserId: string, revieweeUserId: string, rating: number, subject: string) {
  try {
    await sql`
      insert into reviews (reviewer, reviewee, rating, subject)
      values (${reviewerUserId}, ${revieweeUserId}, ${rating}, ${subject})
    `
  } catch (err) {
    console.error("Add Review Error")
    throw err;
  }
}

async function getReviewByTutorId(userId: string) {
  try {
    const reviews = await sql`
      SELECT
      r.*,
      -- Student (Reviewer) Details
      s.firstname AS reviewer_firstname,
      s.lastname AS reviewer_lastname,
      s.gender AS reviewer_gender,
      s.profile_picture AS reviewer_profile_picture,
      s.verified AS reviewer_verified,
      -- Tutor (Reviewee) Details
      t.firstname AS reviewee_firstname,
      t.lastname AS reviewee_lastname,
      t.gender AS reviewee_gender,
      t.profile_picture AS reviewee_profile_picture,
      t.verified AS reviewee_verified
      FROM reviews r
      JOIN students s ON r.reviewer = s.user_uuid
      JOIN tutors t ON r.reviewee = t.user_uuid
      WHERE r.reviewee = ${userId};
    `
    return reviews
  } catch (err) {
    console.error("Get Review by Tutor Id Error")
    throw err;
  }
}

export { addReview, getReviewByTutorId }