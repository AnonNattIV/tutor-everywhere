import sql from "../db/db.ts";
import "../enums/tutorSortBy.ts"
import TutorSortBy from "../enums/tutorSortBy.ts";

async function viewTutorData(userId: string) {
  try {
    const tutor = await sql`
      select user_uuid, firstname, lastname, dateofbirth, gender, profile_picture, bio, verified, preferred_place, province, location, promptpay_picture, verification_picture
      from tutors
      where user_uuid = ${userId}
    `;

    return tutor;
  } catch (err) {
    console.error("View Tutor Data Error");
    throw err;
  }
}


async function getPromptPayPictureByTutorId(userId: string) {
  try {
    const tutor = await sql`
      select promptpay_picture
      from tutors
      where user_uuid = ${userId}
    `;

    return tutor;
  } catch (err) {
    console.error("Get Prompt Pay Picture Error");
    throw err;
  }
}

async function updateTutorProfilePicture(userId: string, profilePicturePath: string) {
  try {
    await sql`
      update tutors
      set profile_picture = ${profilePicturePath}
      where user_uuid = ${userId}
    `
  } catch (err) {
    console.error("Update Tutor Profile Picture Error");
    throw err;
  }
}

async function updateTutorPromptPayPicture(userId: string, promptPayPicture: string) {
  try {
    await sql`
      update tutors
      set promptpay_picture = ${promptPayPicture}
      where user_uuid = ${userId}
    `
  } catch (err) {
    console.error("Update Tutor Prompt Pay Picture Error");
    throw err;
  }
}

async function getTutorVerificationPhoto(userId: string) {
  try {
    await sql`
      select verification_photo
      from tutors
      where user_uuid = ${userId}
    `
  } catch (err) {
    console.error("Get Tutor Verification Photo Error");
    throw err;
  }
}

async function updateTutorVerificationPhoto(userId: string, verificationPicture: string) {
  try {
    await sql`
      update tutors
      set verification_picture = ${verificationPicture}
      where user_uuid = ${userId}
    `
  } catch (err) {
    console.error("Update Tutor Verification Picture Error");
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

async function updateTutorLocation(userId: string, province: string, location: string) {
  try {
    await sql`
      update tutors
      set province = ${province}, location = ${location}
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

async function findTutor(subject?: string, province?: string, location?: string, maxPrice?: string, name?: string, sortBy?: string) {
  try {
    let orderByClause = sql``

    if (sortBy) {
      switch (sortBy) {
        case TutorSortBy.Popular:
          orderByClause = sql`ORDER BY review_count DESC`;
          break;
        case TutorSortBy.TopRated:
          orderByClause = sql`ORDER BY avg_rating DESC`;
          break;
        case TutorSortBy.LowPrice:
          orderByClause = sql`ORDER BY ts.price ASC`;
          break;
        case TutorSortBy.MaxPrice:
          orderByClause = sql`ORDER BY ts.price DESC`;
          break;
        default:
          break;
      }
    }

    const tutors = await sql`
      select 
        t.user_uuid, 
        t.firstname, 
        t.lastname, 
        t.dateofbirth, 
        t.gender, 
        t.profile_picture, 
        t.bio, 
        t.verified, 
        t.province, 
        t.location,
        ts.subject,
        ts.price,
        round(avg(r.rating)::numeric, 2) as avg_rating,
        count(r.rating) as review_count
      from tutors t
      join tutor_subjects ts on t.user_uuid = ts.tutor_uuid
      join reviews r on t.user_uuid = r.reviewee
      where true
        ${subject ? sql` and ts.subject = ${subject}` : sql``}
        ${province ? sql` and t.province = ${province}` : sql``}
        ${location ? sql` and t.location = ${location}` : sql``}
        ${maxPrice ? sql` and ts.price <= ${maxPrice}` : sql``}
        ${name ? sql` and (t.firstname ILIKE ${`%${name}%`} OR t.lastname ILIKE ${`%${name}%`})` : sql``}
      group by
        t.user_uuid, t.firstname, t.lastname, t.dateofbirth, t.gender,
        t.profile_picture, t.bio, t.verified, t.preferred_place,
        t.province, t.location, ts.price, ts.subject
      ${orderByClause}
      `
    return tutors
  } catch (err) {
    console.error("Find Tutor Error");
    throw err;
  }
}

export { viewTutorData, updateTutorBio, updateTutorPreferredPlace, getTutorSubjects,
  addTutorSubject, updateTutorSubjectPrice, deleteTutorSubject, findTutor, updateTutorLocation,
  updateTutorProfilePicture, updateTutorPromptPayPicture, getPromptPayPictureByTutorId,
  updateTutorVerificationPhoto, getTutorVerificationPhoto }