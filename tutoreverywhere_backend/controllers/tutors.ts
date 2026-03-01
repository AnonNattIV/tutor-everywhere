import sql from "../db/db.ts";

async function viewTutorData(userId: string) {
  try {
    const tutor = await sql`
      select user_uuid, firstname, lastname, dateofbirth, gender, profile_picture, bio, verified, preferred_place
      from tutors
      where user_uuid = ${userId}
    `;

    return tutor;
  } catch (err) {
    console.error("View Tutor Data Error");
    throw err;
  }
}

async function updateTutorBio(userId: string, bio: string) {
  try {
    await sql`
      update tutors
      set bio = ${bio}
      where user_uuid = ${userId}
    `
  } catch (err) {
    console.error("Update Tutor Bio Error")
    throw err;
  }
}

async function updateTutorPreferredPlace(userId: string, preferred_place: string) {
  try {
    await sql`
      update tutors
      set preferred_place = ${preferred_place}
      where user_uuid = ${userId}
    `
  } catch (err) {
    console.error("Update Tutor Preferred Place Error")
    throw err;
  }
}

export { viewTutorData, updateTutorBio, updateTutorPreferredPlace }