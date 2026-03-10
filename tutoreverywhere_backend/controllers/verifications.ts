import sql from "../db/db.ts";

async function getTutorRequiredVerifications() {
  try {
    const verifications = await sql`
      select user_uuid, firstname, lastname, gender
      from tutors
      where verification_picture is not null and verified = false
    `
    return verifications;
  } catch (err) {
    console.error("Get Tutor Required Verifications Error")
    throw err;
  }
}

export { getTutorRequiredVerifications }