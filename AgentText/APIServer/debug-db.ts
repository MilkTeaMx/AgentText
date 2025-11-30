/**
 * Debug script to investigate the database schema
 */

import { Database } from 'bun:sqlite'
import { homedir } from 'os'
import { join } from 'path'

const dbPath = join(homedir(), 'Library/Messages/chat.db')
const db = new Database(dbPath, { readonly: true })

console.log('\n=== Investigating chat table for +12488286530 ===\n')

// Query 1: Check chat table entries
const chatQuery = `
SELECT
    chat.ROWID,
    chat.chat_identifier,
    chat.guid,
    chat.service_name,
    chat.display_name
FROM chat
WHERE chat.chat_identifier LIKE '%2488286530%'
   OR chat.guid LIKE '%2488286530%'
LIMIT 5
`

console.log('Chat table entries:')
const chats = db.prepare(chatQuery).all()
console.log(JSON.stringify(chats, null, 2))

// Query 2: Check messages for this number
const messageQuery = `
SELECT
    message.ROWID,
    message.text,
    handle.id as sender,
    chat.chat_identifier,
    chat.guid as chat_guid
FROM message
LEFT JOIN handle ON message.handle_id = handle.ROWID
LEFT JOIN chat_message_join ON message.ROWID = chat_message_join.message_id
LEFT JOIN chat ON chat_message_join.chat_id = chat.ROWID
WHERE handle.id LIKE '%2488286530%'
   OR chat.chat_identifier LIKE '%2488286530%'
   OR chat.guid LIKE '%2488286530%'
ORDER BY message.date DESC
LIMIT 5
`

console.log('\n\nMessages with this number:')
const messages = db.prepare(messageQuery).all()
console.log(JSON.stringify(messages, null, 2))

// Query 3: Check handle table
const handleQuery = `
SELECT * FROM handle
WHERE id LIKE '%2488286530%'
LIMIT 5
`

console.log('\n\nHandle table entries:')
const handles = db.prepare(handleQuery).all()
console.log(JSON.stringify(handles, null, 2))

db.close()
