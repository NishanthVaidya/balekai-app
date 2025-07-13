"use client"

import { useState, useEffect } from "react"
import { useRouter } from "next/navigation"
import { Navbar } from "@/components/navbar"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Switch } from "@/components/ui/switch"
import { Label } from "@/components/ui/label"
import { ArrowLeft } from "lucide-react"

export default function SettingsPage() {
  const [username, setUsername] = useState("John Doe")
  const [emailNotifications, setEmailNotifications] = useState(true)
  const [darkMode, setDarkMode] = useState(false)
  const [isLoading, setIsLoading] = useState(false)
  const [sidebarOpen, setSidebarOpen] = useState(false)
  const router = useRouter()

  // Load settings from localStorage on component mount
  useEffect(() => {
    // Check if user is logged in
    const token = localStorage.getItem("token")
    if (!token) {
      router.push("/login")
      return
    }

    // Load user data
    const userData = localStorage.getItem("user")
    if (userData) {
      try {
        const user = JSON.parse(userData)
        setUsername(user.name || "User")
      } catch (err) {
        console.error("Error parsing user data", err)
      }
    }

    // Load dark mode preference
    const savedDarkMode = localStorage.getItem("darkMode")
    if (savedDarkMode) {
      const isDarkMode = savedDarkMode === "true"
      setDarkMode(isDarkMode)

      // Apply dark mode to document if enabled
      if (isDarkMode) {
        document.documentElement.classList.add("dark-mode")
      } else {
        document.documentElement.classList.remove("dark-mode")
      }
    }

    // Load notification preferences
    const savedEmailNotifications = localStorage.getItem("emailNotifications")
    if (savedEmailNotifications) {
      setEmailNotifications(savedEmailNotifications === "true")
    }
  }, [router])

  // Apply dark mode when the state changes
  useEffect(() => {
    if (darkMode) {
      document.documentElement.classList.add("dark-mode")
    } else {
      document.documentElement.classList.remove("dark-mode")
    }

    // Save preference to localStorage
    localStorage.setItem("darkMode", darkMode.toString())
  }, [darkMode])

  const handleSaveSettings = async () => {
    setIsLoading(true)

    try {
      // Simulate API call
      await new Promise((resolve) => setTimeout(resolve, 1000))

      // Save settings to localStorage
      localStorage.setItem("emailNotifications", emailNotifications.toString())
      localStorage.setItem("darkMode", darkMode.toString())

      // In a real app, you would update the user settings on the server here
    } catch (error) {
      console.error("Failed to update settings:", error)
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div
      className={`min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 flex flex-col ${darkMode ? "dark-theme" : ""}`}
    >
      <Navbar
        username={username}
        sidebarOpen={sidebarOpen}
        onSidebarToggle={() => setSidebarOpen(!sidebarOpen)}
      />

      <div className="container mx-auto px-4 py-4">
        <Button
          variant="ghost"
          className="flex items-center text-gray-700 hover:text-gray-900"
          onClick={() => router.push("/boards")}
        >
          <ArrowLeft size={16} className="mr-2" />
          Back to Boards
        </Button>
      </div>

      <main className="flex-1 container mx-auto py-4 px-4">
        <div className="grid gap-6 md:grid-cols-2">
          <Card>
            <CardHeader>
              <CardTitle>Notifications</CardTitle>
              <CardDescription>Manage how you receive notifications</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex items-center justify-between">
                <Label htmlFor="email-notifications" className="flex flex-col space-y-1">
                  <span>Email Notifications</span>
                  <span className="text-sm text-muted-foreground">Receive email notifications for board updates</span>
                </Label>
                <Switch id="email-notifications" checked={emailNotifications} onCheckedChange={setEmailNotifications} />
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Appearance</CardTitle>
              <CardDescription>Customize how the app looks</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex items-center justify-between">
                <Label htmlFor="dark-mode" className="flex flex-col space-y-1">
                  <span>Dark Mode</span>
                  <span className="text-sm text-muted-foreground">Switch between light and dark theme</span>
                </Label>
                <Switch id="dark-mode" checked={darkMode} onCheckedChange={setDarkMode} />
              </div>
            </CardContent>
          </Card>
        </div>

        <div className="mt-6 flex justify-end">
          <Button
            className="bg-blue-600 hover:bg-blue-700 text-white"
            onClick={handleSaveSettings}
            disabled={isLoading}
          >
            {isLoading ? "Saving..." : "Save Settings"}
          </Button>
        </div>
      </main>

      {/* Add CSS for dark mode */}
      <style jsx global>{`
        .dark-mode {
          --background: #121212;
          --card-background: #1e1e1e;
          --text-color: #e0e0e0;
          --muted-text-color: #a0a0a0;
          --border-color: #333;
        }

        .dark-mode body {
          background: var(--background);
          color: var(--text-color);
        }

        .dark-mode .bg-gradient-to-br {
          background: linear-gradient(to bottom right, #121212, #1a1a1a);
        }

        .dark-mode .card {
          background-color: var(--card-background);
          border-color: var(--border-color);
        }

        .dark-mode h1, .dark-mode h2, .dark-mode h3,
        .dark-mode .card-title {
          color: var(--text-color);
        }

        .dark-mode .card-description,
        .dark-mode .text-muted-foreground {
          color: var(--muted-text-color);
        }
      `}</style>
    </div>
  )
}
