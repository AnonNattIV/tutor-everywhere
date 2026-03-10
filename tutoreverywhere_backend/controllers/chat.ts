import sql from "../db/db.ts";
import { v7 as uuidv7 } from "uuid";

type ChatMessageType = "text" | "location" | "image" | "request_money";

type RequestMoneyPayload = {
  subject: string;
  amount: number;
  hours: number;
  startAt: string;
  endAt: string;
  dateLabel: string;
  locationLabel: string;
  placeName?: string;
  description?: string;
  latitude?: number | null;
  longitude?: number | null;
  promptpayPicturePath: string;
  tutorId: string;
};

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
        image_path text,
        request_payload jsonb,
        created_at timestamptz not null default now(),
        check (message_type in ('text', 'location', 'image', 'request_money'))
      )
    `;

    await sql`
      alter table chat_messages add column if not exists image_path text
    `;

    await sql`
      alter table chat_messages add column if not exists request_payload jsonb
    `;

    // Keep constraints backward-compatible for already-created tables.
    await sql.unsafe(`
      do $$
      declare
        constraint_row record;
      begin
        -- Drop old unnamed/named check constraints from previous schema versions.
        for constraint_row in
          select conname
          from pg_constraint
          where conrelid = 'chat_messages'::regclass
            and contype = 'c'
        loop
          execute format(
            'alter table chat_messages drop constraint %I',
            constraint_row.conname
          );
        end loop;

        alter table chat_messages
          add constraint chat_messages_message_type_check
          check (message_type in ('text', 'location', 'image', 'request_money'));

        alter table chat_messages
          add constraint chat_messages_payload_check
          check (
            (message_type = 'text'
              and message_text is not null
              and length(trim(message_text)) > 0
              and latitude is null
              and longitude is null
              and image_path is null
              and request_payload is null)
            or
            (message_type = 'location'
              and latitude is not null
              and longitude is not null
              and image_path is null
              and request_payload is null)
            or
            (message_type = 'image'
              and image_path is not null
              and latitude is null
              and longitude is null
              and request_payload is null)
            or
            (message_type = 'request_money'
              and request_payload is not null
              and image_path is null
              and latitude is null
              and longitude is null)
          );
      exception
        when duplicate_object then null;
      end $$;
    `);

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
          image_path,
          request_payload,
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
        r.image_path,
        r.request_payload,
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
          image_path,
          request_payload,
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
        image_path,
        request_payload,
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
        longitude,
        image_path,
        request_payload
      )
      values (
        ${messageId},
        ${senderId},
        ${receiverId},
        ${messageType},
        ${text ?? "Shared location"},
        ${latitude},
        ${longitude},
        ${null},
        ${null}
      )
      returning
        message_id,
        sender_id,
        receiver_id,
        message_type,
        message_text,
        latitude,
        longitude,
        image_path,
        request_payload,
        created_at
    `;

    return message;
  } catch (err) {
    console.error("Send Location Message Error");
    throw err;
  }
}

async function sendImageMessage(
  senderId: string,
  receiverId: string,
  imagePath: string,
  text?: string,
) {
  const messageId = uuidv7();
  const messageType: ChatMessageType = "image";
  const caption = text?.trim();

  try {
    const [message] = await sql`
      insert into chat_messages (
        message_id,
        sender_id,
        receiver_id,
        message_type,
        message_text,
        latitude,
        longitude,
        image_path,
        request_payload
      )
      values (
        ${messageId},
        ${senderId},
        ${receiverId},
        ${messageType},
        ${caption && caption.length > 0 ? caption : "Sent an image"},
        ${null},
        ${null},
        ${imagePath},
        ${null}
      )
      returning
        message_id,
        sender_id,
        receiver_id,
        message_type,
        message_text,
        latitude,
        longitude,
        image_path,
        request_payload,
        created_at
    `;

    return message;
  } catch (err) {
    console.error("Send Image Message Error");
    throw err;
  }
}

async function getTutorPromptPayPicturePath(userId: string) {
  try {
    const [row] = await sql`
      select promptpay_picture
      from tutors
      where user_uuid = ${userId}
    `;

    return row?.promptpay_picture?.toString?.() ?? "";
  } catch (err) {
    console.error("Get Tutor PromptPay Picture Error");
    throw err;
  }
}

async function sendRequestMoneyMessage(
  senderId: string,
  receiverId: string,
  payload: RequestMoneyPayload,
) {
  const messageId = uuidv7();
  const messageType: ChatMessageType = "request_money";

  try {
    const summaryText = `Request ${payload.amount} Baht for ${payload.hours} hours`;
    const [message] = await sql`
      insert into chat_messages (
        message_id,
        sender_id,
        receiver_id,
        message_type,
        message_text,
        latitude,
        longitude,
        image_path,
        request_payload
      )
      values (
        ${messageId},
        ${senderId},
        ${receiverId},
        ${messageType},
        ${summaryText},
        ${null},
        ${null},
        ${null},
        ${sql.json(payload)}
      )
      returning
        message_id,
        sender_id,
        receiver_id,
        message_type,
        message_text,
        latitude,
        longitude,
        image_path,
        request_payload,
        created_at
    `;

    return message;
  } catch (err) {
    console.error("Send Request Money Message Error");
    throw err;
  }
}

export {
  ensureChatTables,
  getConversations,
  getMessages,
  sendTextMessage,
  sendLocationMessage,
  sendImageMessage,
  getTutorPromptPayPicturePath,
  sendRequestMoneyMessage,
};
