import sql from "../db/db.ts";
import { v7 as uuidv7 } from "uuid";

type ChatMessageType = "text" | "location";

async function ensureChatTables() {
  try {
    // Generic chat table: either plain text or pinned location payload.
    await sql`
      create table if not exists chat_messages (
        message_id uuid primary key,
        sender_id uuid not null references users(user_uuid) on delete cascade,
        receiver_id uuid not null references users(user_uuid) on delete cascade,
        message_type text not null default 'text',
        message_text text,
        latitude double precision,
        longitude double precision,
        created_at timestamptz not null default now(),
        check (message_type in ('text', 'location')),
        check (
          (message_type = 'text' and message_text is not null and length(trim(message_text)) > 0 and latitude is null and longitude is null)
          or
          (message_type = 'location' and latitude is not null and longitude is not null)
        )
      )
    `;

    await sql`
      create index if not exists chat_messages_pair_created_idx
      on chat_messages ((least(sender_id, receiver_id)), (greatest(sender_id, receiver_id)), created_at desc)
    `;
  } catch (err) {
    console.error("Ensure Chat Tables Error");
    throw err;
  }
}

async function getConversations(userId: string) {
  try {
    const conversations = await sql`
      -- Collect all messages involving current user and compute the counterpart id.
      with scoped as (
        select
          message_id,
          sender_id,
          receiver_id,
          message_type,
          message_text,
          latitude,
          longitude,
          created_at,
          case
            when sender_id = ${userId} then receiver_id
            else sender_id
          end as partner_id
        from chat_messages
        where sender_id = ${userId} or receiver_id = ${userId}
      ),
      -- Keep the newest message per counterpart as conversation preview.
      ranked as (
        select
          *,
          row_number() over (
            partition by partner_id
            order by created_at desc, message_id desc
          ) as row_num
        from scoped
      )
      select
        r.message_id,
        r.sender_id,
        r.receiver_id,
        r.message_type,
        r.message_text,
        r.latitude,
        r.longitude,
        r.created_at,
        r.partner_id,
        u.role as partner_role,
        u.username as partner_username,
        coalesce(s.firstname, t.firstname, u.username) as partner_firstname,
        coalesce(s.lastname, t.lastname, '') as partner_lastname,
        coalesce(s.profile_picture, t.profile_picture, '') as partner_profile_picture
      from ranked as r
      join users as u on u.user_uuid = r.partner_id
      left join students as s on s.user_uuid = r.partner_id
      left join tutors as t on t.user_uuid = r.partner_id
      where r.row_num = 1
      order by r.created_at desc, r.message_id desc
    `;

    return conversations;
  } catch (err) {
    console.error("Get Conversations Error");
    throw err;
  }
}

async function getMessages(userId: string, otherUserId: string, limit: number = 200) {
  try {
    const messages = await sql`
      -- Fetch newest rows first for performance, then re-order ascending for UI display.
      select * from (
        select
          message_id,
          sender_id,
          receiver_id,
          message_type,
          message_text,
          latitude,
          longitude,
          created_at
        from chat_messages
        where
          (sender_id = ${userId} and receiver_id = ${otherUserId})
          or
          (sender_id = ${otherUserId} and receiver_id = ${userId})
        order by created_at desc, message_id desc
        limit ${limit}
      ) as recent_messages
      order by created_at asc, message_id asc
    `;

    return messages;
  } catch (err) {
    console.error("Get Messages Error");
    throw err;
  }
}

async function sendTextMessage(senderId: string, receiverId: string, text: string) {
  const messageId = uuidv7();
  const messageType: ChatMessageType = "text";

  try {
    const [message] = await sql`
      insert into chat_messages (
        message_id,
        sender_id,
        receiver_id,
        message_type,
        message_text
      )
      values (
        ${messageId},
        ${senderId},
        ${receiverId},
        ${messageType},
        ${text}
      )
      returning
        message_id,
        sender_id,
        receiver_id,
        message_type,
        message_text,
        latitude,
        longitude,
        created_at
    `;

    return message;
  } catch (err) {
    console.error("Send Text Message Error");
    throw err;
  }
}

async function sendLocationMessage(
  senderId: string,
  receiverId: string,
  latitude: number,
  longitude: number,
  text?: string,
) {
  const messageId = uuidv7();
  const messageType: ChatMessageType = "location";

  try {
    const [message] = await sql`
      insert into chat_messages (
        message_id,
        sender_id,
        receiver_id,
        message_type,
        message_text,
        latitude,
        longitude
      )
      values (
        ${messageId},
        ${senderId},
        ${receiverId},
        ${messageType},
        ${text ?? "Shared location"},
        ${latitude},
        ${longitude}
      )
      returning
        message_id,
        sender_id,
        receiver_id,
        message_type,
        message_text,
        latitude,
        longitude,
        created_at
    `;

    return message;
  } catch (err) {
    console.error("Send Location Message Error");
    throw err;
  }
}

export {
  ensureChatTables,
  getConversations,
  getMessages,
  sendTextMessage,
  sendLocationMessage,
};
