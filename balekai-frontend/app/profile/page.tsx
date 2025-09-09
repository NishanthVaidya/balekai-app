"use client"

import { useState, useEffect } from "react"
import { useRouter } from "next/navigation"
import { Navbar } from "@/components/navbar"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { ArrowLeft, CheckCircle, AlertCircle } from "lucide-react"
import api from "../utils/api"

export default function ProfilePage() {
  const [username, setUsername] = useState("")
  const [email, setEmail] = useState("")
  const [userId, setUserId] = useState("")
  const [isEditing, setIsEditing] = useState(false)
  const [isLoading, setIsLoading] = useState(false)
  const [sidebarOpen, setSidebarOpen] = useState(false)
  const [message, setMessage] = useState<{ type: 'success' | 'error', text: string } | null>(null)
  const router = useRouter()

  useEffect(() => {
    const token = localStorage.getItem("token")
    if (!token) {
      router.push("/login")
      return
    }

    // Fetch user data from backend
    const fetchUserData = async () => {
      try {
        const userData = localStorage.getItem("user")
        if (userData) {
          const user = JSON.parse(userData)
          setUserId(user.id)
          
          // Fetch fresh user data from backend
          const response = await api.get(`/users/${user.id}`)
          const userFromBackend = response.data
          setUsername(userFromBackend.name || "User")
          setEmail(userFromBackend.email || "")
        }
      } catch (err) {
        console.error("Error fetching user data:", err)
        setMessage({ type: 'error', text: 'Failed to load user profile' })
      }
    }

    fetchUserData()
  }, [router])

  const handleSaveProfile = async () => {
    if (!userId) {
      setMessage({ type: 'error', text: 'User ID not found' })
      return
    }

    // Basic validation
    if (!username.trim()) {
      setMessage({ type: 'error', text: 'Username is required' })
      return
    }

    if (!email.trim()) {
      setMessage({ type: 'error', text: 'Email is required' })
      return
    }

    // Email validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    if (!emailRegex.test(email)) {
      setMessage({ type: 'error', text: 'Please enter a valid email address' })
      return
    }

    setIsLoading(true)
    setMessage(null)

    try {
      const response = await api.put(`/users/${userId}`, {
        name: username.trim(),
        email: email.trim()
      })

      // Update localStorage with new user data
      const updatedUser = response.data
      localStorage.setItem("user", JSON.stringify(updatedUser))

      setMessage({ type: 'success', text: 'Profile updated successfully!' })
      setIsEditing(false)

      // Clear success message after 3 seconds
      setTimeout(() => setMessage(null), 3000)

    } catch (error: unknown) {
      console.error("Failed to update profile:", error)
      
      let errorMessage = "Failed to update profile. Please try again."
      
      if (error && typeof error === 'object' && 'response' in error && error.response && typeof error.response === 'object' && 'data' in error.response) {
        const responseData = error.response.data
        if (typeof responseData === 'string') {
          errorMessage = responseData
        } else if (responseData && typeof responseData === 'object' && 'message' in responseData && typeof responseData.message === 'string') {
          errorMessage = responseData.message
        }
      }
      
      setMessage({ type: 'error', text: errorMessage })
    } finally {
      setIsLoading(false)
    }
  }

  const handleCancel = () => {
    // Reset form to original values
    const userData = localStorage.getItem("user")
    if (userData) {
      try {
        const user = JSON.parse(userData)
        setUsername(user.name || "")
        setEmail(user.email || "")
      } catch (err) {
        console.error("Error parsing user data", err)
      }
    }
    setIsEditing(false)
    setMessage(null)
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 flex flex-col">
      <Navbar
        username={username}
        sidebarOpen={sidebarOpen}
        onSidebarToggle={() => setSidebarOpen(!sidebarOpen)}
        title="Your Profile"
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
        <Card className="max-w-md mx-auto">
          <CardHeader>
            <CardTitle>Profile Information</CardTitle>
            <CardDescription>Update your account details</CardDescription>
          </CardHeader>
          
          {/* Message Display */}
          {message && (
            <div className={`mx-6 mb-4 p-3 rounded-md flex items-center ${
              message.type === 'success' 
                ? 'bg-green-50 text-green-800 border border-green-200' 
                : 'bg-red-50 text-red-800 border border-red-200'
            }`}>
              {message.type === 'success' ? (
                <CheckCircle className="w-4 h-4 mr-2" />
              ) : (
                <AlertCircle className="w-4 h-4 mr-2" />
              )}
              <span className="text-sm">{message.text}</span>
            </div>
          )}
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="username">Username</Label>
              <Input
                id="username"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                disabled={!isEditing}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="email">Email</Label>
              <Input
                id="email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                disabled={!isEditing}
              />
            </div>
          </CardContent>

          <div className="flex justify-between px-6 pb-6">
            {isEditing ? (
              <>
                <Button variant="outline" onClick={handleCancel}>
                  Cancel
                </Button>
                <Button
                  className="bg-blue-600 hover:bg-blue-700 text-white"
                  onClick={handleSaveProfile}
                  disabled={isLoading}
                >
                  {isLoading ? "Saving..." : "Save Changes"}
                </Button>
              </>
            ) : (
              <Button className="bg-blue-600 hover:bg-blue-700 text-white ml-auto" onClick={() => setIsEditing(true)}>
                Edit Profile
              </Button>
            )}
          </div>
        </Card>
      </main>
    </div>
  )
}
