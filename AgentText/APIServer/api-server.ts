/**
 * REST API Server for iMessage SDK
 *
 * This Express server wraps the @photon-ai/imessage-kit SDK
 * and exposes all functionality via HTTP endpoints.
 *
 * @example Start the server:
 * bun run api-server.ts
 * or
 * tsx api-server.ts
 */

import express, { type Request, type Response } from 'express'
import cors from 'cors'
import { IMessageSDK, loggerPlugin, type Message, type MessageFilter, type ListChatsOptions } from './src/index'

const app = express()
const PORT = process.env.PORT || 3000

// Middleware
app.use(cors())
app.use(express.json())

// Initialize SDK
const sdk = new IMessageSDK({
    debug: true,
    maxConcurrent: 5,
    plugins: [loggerPlugin({ level: 'info', colored: true })],
    watcher: {
        excludeOwnMessages: false  // Include own messages for @mention detection
    }
})

// Health check endpoint
app.get('/health', (_req: Request, res: Response) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() })
})

// ==================== Message Endpoints ====================

/**
 * GET /messages - Query messages
 * Query parameters:
 * - sender: Filter by sender (phone/email)
 * - chatId: Filter by chat ID (for getting messages from specific conversation)
 * - unreadOnly: boolean - Only unread messages
 * - limit: number - Max messages to return
 * - since: ISO date string - Messages since this date
 * - search: string - Search message text
 * - hasAttachments: boolean - Only messages with attachments
 * - excludeOwnMessages: boolean - Exclude your own messages (default: true)
 */
app.get('/messages', async (req: Request, res: Response) => {
    try {
        const filter: MessageFilter = {
            sender: req.query.sender as string | undefined,
            chatId: req.query.chatId as string | undefined,
            unreadOnly: req.query.unreadOnly === 'true',
            limit: req.query.limit ? Number(req.query.limit) : undefined,
            since: req.query.since ? new Date(req.query.since as string) : undefined,
            search: req.query.search as string | undefined,
            hasAttachments: req.query.hasAttachments === 'true' || undefined,
            excludeOwnMessages: req.query.excludeOwnMessages !== 'false' // default true
        }

        const result = await sdk.getMessages(filter)
        res.json(result)
    } catch (error) {
        console.error('Error fetching messages:', error)
        res.status(500).json({
            error: 'Failed to fetch messages',
            message: error instanceof Error ? error.message : String(error)
        })
    }
})

/**
 * GET /messages/unread - Get unread messages grouped by sender
 */
app.get('/messages/unread', async (_req: Request, res: Response) => {
    try {
        const result = await sdk.getUnreadMessages()
        res.json(result)
    } catch (error) {
        console.error('Error fetching unread messages:', error)
        res.status(500).json({
            error: 'Failed to fetch unread messages',
            message: error instanceof Error ? error.message : String(error)
        })
    }
})

// ==================== Send Endpoints ====================

/**
 * POST /send - Send a message
 * Body:
 * {
 *   "to": "+1234567890" | "user@example.com" | "chat123...",
 *   "content": "text" | { "text": "...", "images": [...], "files": [...] }
 * }
 */
app.post('/send', async (req: Request, res: Response) => {
    try {
        const { to, content } = req.body

        if (!to) {
            return res.status(400).json({ error: 'Missing required field: to' })
        }

        if (!content) {
            return res.status(400).json({ error: 'Missing required field: content' })
        }

        const result = await sdk.send(to, content)
        res.json(result)
    } catch (error) {
        console.error('Error sending message:', error)
        res.status(500).json({
            error: 'Failed to send message',
            message: error instanceof Error ? error.message : String(error)
        })
    }
})

/**
 * POST /send/batch - Send multiple messages
 * Body:
 * {
 *   "messages": [
 *     { "to": "+1234567890", "content": "Hello" },
 *     { "to": "user@example.com", "content": { "text": "Hi", "images": ["photo.jpg"] } }
 *   ]
 * }
 */
app.post('/send/batch', async (req: Request, res: Response) => {
    try {
        const { messages } = req.body

        if (!messages || !Array.isArray(messages)) {
            return res.status(400).json({ error: 'Missing or invalid field: messages (must be array)' })
        }

        const results = await sdk.sendBatch(messages)
        res.json(results)
    } catch (error) {
        console.error('Error sending batch messages:', error)
        res.status(500).json({
            error: 'Failed to send batch messages',
            message: error instanceof Error ? error.message : String(error)
        })
    }
})

/**
 * POST /send/file - Send a file
 * Body:
 * {
 *   "to": "+1234567890",
 *   "filePath": "/path/to/file.pdf",
 *   "text": "Optional message"
 * }
 */
app.post('/send/file', async (req: Request, res: Response) => {
    try {
        const { to, filePath, text } = req.body

        if (!to || !filePath) {
            return res.status(400).json({ error: 'Missing required fields: to, filePath' })
        }

        const result = await sdk.sendFile(to, filePath, text)
        res.json(result)
    } catch (error) {
        console.error('Error sending file:', error)
        res.status(500).json({
            error: 'Failed to send file',
            message: error instanceof Error ? error.message : String(error)
        })
    }
})

/**
 * POST /send/files - Send multiple files
 * Body:
 * {
 *   "to": "+1234567890",
 *   "filePaths": ["/file1.pdf", "/file2.csv"],
 *   "text": "Optional message"
 * }
 */
app.post('/send/files', async (req: Request, res: Response) => {
    try {
        const { to, filePaths, text } = req.body

        if (!to || !filePaths || !Array.isArray(filePaths)) {
            return res.status(400).json({ error: 'Missing required fields: to, filePaths (array)' })
        }

        const result = await sdk.sendFiles(to, filePaths, text)
        res.json(result)
    } catch (error) {
        console.error('Error sending files:', error)
        res.status(500).json({
            error: 'Failed to send files',
            message: error instanceof Error ? error.message : String(error)
        })
    }
})

// ==================== Chat Endpoints ====================

/**
 * GET /chats - List chats
 * Query parameters:
 * - type: 'group' | 'direct' - Filter by chat type
 * - hasUnread: boolean - Only chats with unread messages
 * - sortBy: 'recent' | 'name' - Sort order
 * - search: string - Search chat names
 * - limit: number - Max chats to return
 */
app.get('/chats', async (req: Request, res: Response) => {
    try {
        const options: ListChatsOptions = {
            type: req.query.type as 'group' | 'direct' | undefined,
            hasUnread: req.query.hasUnread === 'true' ? true : undefined,
            sortBy: req.query.sortBy as 'recent' | 'name' | undefined,
            search: req.query.search as string | undefined,
            limit: req.query.limit ? Number(req.query.limit) : undefined
        }

        const chats = await sdk.listChats(options)
        res.json(chats)
    } catch (error) {
        console.error('Error listing chats:', error)
        res.status(500).json({
            error: 'Failed to list chats',
            message: error instanceof Error ? error.message : String(error)
        })
    }
})

// ==================== Watcher Endpoints ====================

let watcherActive = false
const activeConnections = new Set<Response>()

/**
 * POST /watcher/start - Start watching for new messages
 * Body (optional):
 * {
 *   "webhook": {
 *     "url": "https://your-server.com/webhook",
 *     "headers": { "Authorization": "Bearer token" }
 *   }
 * }
 */
app.post('/watcher/start', async (req: Request, res: Response) => {
    try {
        if (watcherActive) {
            return res.status(400).json({ error: 'Watcher already running' })
        }

        await sdk.startWatching({
            onMessage: async (message: Message) => {
                console.log(`[Watcher] New message from ${message.sender}: ${message.text}`)
                console.log(`[Watcher] Message chatId: ${message.chatId}`)
                console.log(`[Watcher] Full message:`, JSON.stringify(message, null, 2))

                // Broadcast to all SSE connections
                const data = JSON.stringify({ event: 'message', message })
                activeConnections.forEach(conn => {
                    conn.write(`data: ${data}\n\n`)
                })
            },
            onError: (error: Error) => {
                console.error('[Watcher] Error:', error)

                // Broadcast error to all SSE connections
                const data = JSON.stringify({ event: 'error', error: error.message })
                activeConnections.forEach(conn => {
                    conn.write(`data: ${data}\n\n`)
                })
            }
        })

        watcherActive = true
        res.json({ status: 'Watcher started', timestamp: new Date().toISOString() })
    } catch (error) {
        console.error('Error starting watcher:', error)
        res.status(500).json({
            error: 'Failed to start watcher',
            message: error instanceof Error ? error.message : String(error)
        })
    }
})

/**
 * POST /watcher/stop - Stop watching for new messages
 */
app.post('/watcher/stop', (_req: Request, res: Response) => {
    try {
        if (!watcherActive) {
            return res.status(400).json({ error: 'Watcher not running' })
        }

        sdk.stopWatching()
        watcherActive = false

        // Close all SSE connections
        activeConnections.forEach(conn => {
            conn.end()
        })
        activeConnections.clear()

        res.json({ status: 'Watcher stopped', timestamp: new Date().toISOString() })
    } catch (error) {
        console.error('Error stopping watcher:', error)
        res.status(500).json({
            error: 'Failed to stop watcher',
            message: error instanceof Error ? error.message : String(error)
        })
    }
})

/**
 * GET /watcher/status - Get watcher status
 */
app.get('/watcher/status', (_req: Request, res: Response) => {
    res.json({
        active: watcherActive,
        connections: activeConnections.size,
        timestamp: new Date().toISOString()
    })
})

/**
 * GET /watcher/stream - Server-Sent Events stream for real-time messages
 * This endpoint keeps the connection open and streams messages as they arrive
 */
app.get('/watcher/stream', (req: Request, res: Response) => {
    // Set SSE headers
    res.setHeader('Content-Type', 'text/event-stream')
    res.setHeader('Cache-Control', 'no-cache')
    res.setHeader('Connection', 'keep-alive')
    res.flushHeaders()

    // Add to active connections
    activeConnections.add(res)

    // Send initial connection message
    res.write(`data: ${JSON.stringify({ event: 'connected', timestamp: new Date().toISOString() })}\n\n`)

    // Remove connection when client disconnects
    req.on('close', () => {
        activeConnections.delete(res)
        console.log(`[SSE] Client disconnected. Active connections: ${activeConnections.size}`)
    })

    // Keep connection alive with periodic heartbeat
    const heartbeat = setInterval(() => {
        res.write(`:heartbeat ${Date.now()}\n\n`)
    }, 30000) // Every 30 seconds

    req.on('close', () => {
        clearInterval(heartbeat)
    })
})

// ==================== Utility Endpoints ====================

/**
 * GET /test - Send a test message to yourself
 */
app.get('/test', async (_req: Request, res: Response) => {
    try {
        const testNumber = '+12488433255'
        const result = await sdk.send(testNumber, 'Test message from iMessage API - everything is working! 🎉')
        res.json({
            status: 'Test message sent',
            result,
            timestamp: new Date().toISOString()
        })
    } catch (error) {
        console.error('Error sending test message:', error)
        res.status(500).json({
            error: 'Failed to send test message',
            message: error instanceof Error ? error.message : String(error)
        })
    }
})

/**
 * GET /info - Get SDK info
 */
app.get('/info', (_req: Request, res: Response) => {
    res.json({
        name: '@photon-ai/imessage-kit REST API',
        version: '1.0.0',
        endpoints: {
            messages: {
                'GET /messages': 'Query messages',
                'GET /messages/unread': 'Get unread messages'
            },
            send: {
                'POST /send': 'Send a message',
                'POST /send/batch': 'Send multiple messages',
                'POST /send/file': 'Send a file',
                'POST /send/files': 'Send multiple files'
            },
            chats: {
                'GET /chats': 'List chats'
            },
            watcher: {
                'POST /watcher/start': 'Start message watcher',
                'POST /watcher/stop': 'Stop message watcher',
                'GET /watcher/status': 'Get watcher status',
                'GET /watcher/stream': 'Stream messages via SSE'
            },
            utility: {
                'GET /health': 'Health check',
                'GET /info': 'API info',
                'GET /test': 'Send a test message to yourself'
            }
        }
    })
})

// Error handling middleware
app.use((err: Error, _req: Request, res: Response, _next: Function) => {
    console.error('Unhandled error:', err)
    res.status(500).json({
        error: 'Internal server error',
        message: err.message
    })
})

// Start server
const server = app.listen(PORT, () => {
    console.log(`\n🚀 iMessage API Server running on http://localhost:${PORT}`)
    console.log(`📚 API Info: http://localhost:${PORT}/info`)
    console.log(`❤️  Health Check: http://localhost:${PORT}/health\n`)
})

// Graceful shutdown
process.on('SIGTERM', async () => {
    console.log('\n🛑 Shutting down server...')

    // Close all SSE connections
    activeConnections.forEach(conn => conn.end())
    activeConnections.clear()

    // Stop watcher if active
    if (watcherActive) {
        sdk.stopWatching()
    }

    // Close SDK
    await sdk.close()

    // Close server
    server.close(() => {
        console.log('✅ Server closed')
        process.exit(0)
    })
})

process.on('SIGINT', async () => {
    console.log('\n🛑 Shutting down server...')

    // Close all SSE connections
    activeConnections.forEach(conn => conn.end())
    activeConnections.clear()

    // Stop watcher if active
    if (watcherActive) {
        sdk.stopWatching()
    }

    // Close SDK
    await sdk.close()

    // Close server
    server.close(() => {
        console.log('✅ Server closed')
        process.exit(0)
    })
})