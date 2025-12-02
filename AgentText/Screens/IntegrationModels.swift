import SwiftUI

// Integration data model for grid
struct Integration: Identifiable {
    let id: String
    let name: String
    let iconName: String
    let logoURL: String?
}

// Integration info for configuration
struct IntegrationInfo: Identifiable {
    let id: String
    let name: String
    let icon: String
    let description: String
    let placeholder: String
}

// Default integrations list
extension Integration {
    static let defaultIntegrations: [Integration] = [
        // Row 1
        Integration(id: "google_calendar", name: "Google Calendar", iconName: "calendar", logoURL: "https://logo.clearbit.com/google.com"),
        Integration(id: "notion", name: "Notion", iconName: "doc.text", logoURL: "https://logo.clearbit.com/notion.so"),
        Integration(id: "slack", name: "Slack", iconName: "message", logoURL: "https://logo.clearbit.com/slack.com"),
        
        // Row 2
        Integration(id: "github", name: "GitHub", iconName: "chevron.left.forwardslash.chevron.right", logoURL: "https://logo.clearbit.com/github.com"),
        Integration(id: "trello", name: "Trello", iconName: "square.grid.2x2", logoURL: "https://logo.clearbit.com/trello.com"),
        Integration(id: "asana", name: "Asana", iconName: "checklist", logoURL: "https://logo.clearbit.com/asana.com"),
        
        // Row 3
        Integration(id: "jira", name: "Jira", iconName: "ticket", logoURL: "https://logo.clearbit.com/atlassian.com"),
        Integration(id: "linear", name: "Linear", iconName: "line.3.horizontal", logoURL: "https://logo.clearbit.com/linear.app"),
        Integration(id: "figma", name: "Figma", iconName: "paintbrush", logoURL: "https://logo.clearbit.com/figma.com"),
        
        // Row 4
        Integration(id: "gmail", name: "Gmail", iconName: "envelope.fill", logoURL: "https://logo.clearbit.com/gmail.com"),
        Integration(id: "google_drive", name: "Google Drive", iconName: "externaldrive.fill", logoURL: "https://logo.clearbit.com/drive.google.com"),
        Integration(id: "dropbox", name: "Dropbox", iconName: "square.stack.3d.up.fill", logoURL: "https://logo.clearbit.com/dropbox.com"),
        
        // Row 5
        Integration(id: "zoom", name: "Zoom", iconName: "video.fill", logoURL: "https://logo.clearbit.com/zoom.us"),
        Integration(id: "microsoft_teams", name: "Microsoft Teams", iconName: "person.3.fill", logoURL: "https://logo.clearbit.com/teams.microsoft.com"),
        Integration(id: "discord", name: "Discord", iconName: "message.fill", logoURL: "https://logo.clearbit.com/discord.com"),
        
        // Row 6
        Integration(id: "twitter", name: "Twitter", iconName: "at", logoURL: "https://logo.clearbit.com/twitter.com"),
        Integration(id: "linkedin", name: "LinkedIn", iconName: "person.2.fill", logoURL: "https://logo.clearbit.com/linkedin.com"),
        Integration(id: "airtable", name: "Airtable", iconName: "tablecells.fill", logoURL: "https://logo.clearbit.com/airtable.com"),
        
        // Row 7
        Integration(id: "monday", name: "Monday.com", iconName: "calendar", logoURL: "https://logo.clearbit.com/monday.com"),
        Integration(id: "clickup", name: "ClickUp", iconName: "checklist", logoURL: "https://logo.clearbit.com/clickup.com"),
        Integration(id: "stripe", name: "Stripe", iconName: "creditcard.fill", logoURL: "https://logo.clearbit.com/stripe.com"),
        
        // Row 8
        Integration(id: "zapier", name: "Zapier", iconName: "bolt.fill", logoURL: "https://logo.clearbit.com/zapier.com"),
        Integration(id: "hubspot", name: "HubSpot", iconName: "chart.bar.fill", logoURL: "https://logo.clearbit.com/hubspot.com"),
        Integration(id: "salesforce", name: "Salesforce", iconName: "cloud.fill", logoURL: "https://logo.clearbit.com/salesforce.com")
    ]
}

// Helper to create IntegrationInfo from Integration
func getIntegrationInfo(for integration: Integration) -> IntegrationInfo {
    switch integration.id {
    case "google_calendar":
        return IntegrationInfo(
            id: "google_calendar",
            name: "Google Calendar",
            icon: "calendar",
            description: "Access and manage your Google Calendar events",
            placeholder: "Enter your Google Calendar API key"
        )
    case "notion":
        return IntegrationInfo(
            id: "notion",
            name: "Notion",
            icon: "doc.text",
            description: "Access and manage your Notion pages and databases",
            placeholder: "Enter your Notion integration token (secret_...)"
        )
    default:
        return IntegrationInfo(
            id: integration.id,
            name: integration.name,
            icon: integration.iconName,
            description: "Connect \(integration.name) to use with your agents",
            placeholder: "Enter your \(integration.name) API key"
        )
    }
}

