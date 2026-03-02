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

async function getTutorSubjects(userId: string) {
  try {
    const subjects = await sql`
      select tutor_uuid, subject, price
      from tutor_subjects
      where tutor_uuid = ${userId}
    `
    return subjects;
  } catch (err) {
    console.error("Get Tutor Subjects Error")
    throw err;
  }
}

async function addTutorSubject(userId : string, subject: string, price: number) {
  try {
    const tutor_subject = await sql`
      insert into tutor_subjects (tutor_uuid, subject, price)
      values (${userId}, ${subject}, ${price})

    `
    return tutor_subject
  } catch (err) {
    console.error("Add Tutor Subject Error")
    throw err;
  }
}

async function updateTutorSubjectPrice(userId : string, subject: string, price: number) {
  try {
    await sql`
      update tutor_subjects
      set price = ${price}
      where tutor_uuid = ${userId} and subject = ${subject}
    `
  } catch (err) {
    console.error("Update Tutor Subject Error")
    throw err;
  }
}

async function deleteTutorSubject(userId : string, subject: string) {
  try {
    await sql`
      delete from tutor_subjects
      where tutor_uuid = ${userId} and subject = ${subject}
    `
  } catch (err) {
    console.error("Delete Tutor Subject Error")
    throw err;
  }
}

export { viewTutorData, updateTutorBio, updateTutorPreferredPlace, getTutorSubjects, addTutorSubject, updateTutorSubjectPrice, deleteTutorSubject }