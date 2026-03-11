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

async function acceptVerification(tutorId: string) {
  try {
    await sql`
    update tutors
    set verified = true
    where user_uuid = ${tutorId}
    `
  } catch (err) {
    console.error("Accept verification error")
    throw err;
  }
}


async function denyVerification(tutorId: string) {
  try {
    await sql`
    update tutors
    set verification_picture = null
    where user_uuid = ${tutorId}
    `
  } catch (err) {
    console.error("Deny verification error")
    throw err;
  }
}

export { getTutorRequiredVerifications, acceptVerification, denyVerification }