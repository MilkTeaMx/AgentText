/**
 * Type definitions for the iMessage REST API
 *
 * These types can be used in client applications that call the API
 */

// ==================== Request Types ====================

export interface SendMessageRequest {
    to: string // Phone number, email, or chatId
    content: string | {
        text?: string
        images?: string[]
        files?: string[]
    }
}

export interface BatchSendRequest {
    messages: Array<{
        to: string
        content: string | {
            text?: string
            images?: string[]
            files?: string[]
        }
    }>
}

export interface SendFileRequest {
    to: string
    filePath: string
    text?: string
}

export interface SendFilesRequest {
    to: string
    filePaths: string[]
    text?: string
}

export interface StartWatcherRequest {
    webhook?: {
        url: string
        headers?: Record<string, string>
    }
}

export interface MessageQueryParams {
    sender?: string
    unreadOnly?: boolean
    limit?: number
    since?: string // ISO date string
    search?: string
    hasAttachments?: boolean
    excludeOwnMessages?: boolean
}

export interface ChatQueryParams {
    type?: 'group' | 'direct'
    hasUnread?: boolean
    sortBy?: 'recent' | 'name'
    search?: string
    limit?: number
}

// ==================== Response Types ====================

export interface ApiError {
    error: string
    message: string
}

export interface HealthResponse {
    status: 'ok'
    timestamp: string
}

export interface Attachment {
    filename: string
    path: string
    mimeType: string | null
}

export interface Message {
    id: string
    guid: string
    text: string | null
    sender: string
    senderName: string | null
    chatId: string
    isGroupChat: boolean
    isFromMe: boolean
    isRead: boolean
    service: 'iMessage' | 'SMS' | 'RCS'
    attachments: readonly Attachment[]
    date: Date
}

export interface MessageQueryResult {
    messages: readonly Message[]
    total: number
    unreadCount: number
}

export interface UnreadMessagesResult {
    groups: Array<{
        sender: string
        messages: readonly Message[]
    }>
    total: number
    senderCount: number
}

export interface SendResult {
    sentAt: Date
    message?: Message // Only available if watcher is running
}

export interface BatchSendResult {
    to: string
    success: boolean
    result?: SendResult
    error?: string
}

export interface ChatSummary {
    chatId: string
    guid: string
    displayName: string
    lastMessageAt: Date | null
    isGroup: boolean
    unreadCount: number
}

export interface WatcherStatus {
    active: boolean
    connections: number
    timestamp: string
}

export interface WatcherStartResponse {
    status: string
    timestamp: string
}

export interface WatcherStopResponse {
    status: string
    timestamp: string
}

export interface SSEMessage {
    event: 'connected' | 'message' | 'error'
    message?: Message
    error?: string
    timestamp?: string
}

export interface ApiInfo {
    name: string
    version: string
    endpoints: {
        messages: Record<string, string>
        send: Record<string, string>
        chats: Record<string, string>
        watcher: Record<string, string>
        utility: Record<string, string>
    }
}

// ==================== Client Helper Types ====================

/**
 * Type-safe API client configuration
 */
export interface ApiClientConfig {
    baseUrl: string
    timeout?: number
    headers?: Record<string, string>
}

/**
 * Response wrapper for API calls
 */
export type ApiResponse<T> =
    | { success: true; data: T }
    | { success: false; error: ApiError }
