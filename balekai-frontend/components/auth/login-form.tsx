"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { zodResolver } from "@hookform/resolvers/zod"
import { useForm } from "react-hook-form"
import * as z from "zod"
import Link from "next/link"
import api from "@/app/utils/api"
import { setTokens } from "@/app/utils/token"

import { Button } from "@/components/ui/button"
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form"
import { Input } from "@/components/ui/input"
// import { signInWithGoogle } from "@/lib/firebase" // Google sign-in disabled

const formSchema = z.object({
  email: z.string().email({ message: "Please enter a valid email." }),
  password: z.string().min(8, { message: "Password must be at least 8 characters." }),
})

export function LoginForm() {
  const router = useRouter()
  const [isLoading, setIsLoading] = useState(false)
  const [errorMessage, setErrorMessage] = useState("")

  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      email: "",
      password: "",
    },
  })

  const onSubmit = async (data: z.infer<typeof formSchema>) => {
    setIsLoading(true)
    setErrorMessage("") // Clear any previous error messages
    try {
      // Call backend login endpoint
      const response = await api.post("/auth/login", {
        email: data.email,
        password: data.password,
      })

      const tokenData = response.data

      // Preferred new format: tokens plus user payload
      if (tokenData && tokenData.accessToken && tokenData.refreshToken && tokenData.user) {
        setTokens(tokenData.accessToken, tokenData.refreshToken)
        localStorage.setItem("user", JSON.stringify(tokenData.user))
      } else if (typeof tokenData === 'string') {
        // Legacy fallback
        localStorage.setItem("token", tokenData)
        localStorage.setItem("user", JSON.stringify({ email: data.email, name: data.email.split("@")[0] }))
      } else if (tokenData && tokenData.accessToken && tokenData.refreshToken) {
        // Tokens without user payload: keep minimal user as fallback
        setTokens(tokenData.accessToken, tokenData.refreshToken)
        localStorage.setItem("user", JSON.stringify({ email: data.email, name: data.email.split("@")[0] }))
      } else {
        throw new Error("Invalid token response format")
      }

      router.push("/boards")
    } catch (error: unknown) {
      const errorMsg = (error as { response?: { data?: string } })?.response?.data || "Login failed. Please try again."
      setErrorMessage(errorMsg)
    } finally {
      setIsLoading(false)
    }
  }

  // Google login functionality disabled
  // const handleGoogleLogin = async () => { ... }

  return (
    <div className="balekai-card">
      <div className="mb-6 text-center">
        <h2 className="text-2xl font-bold text-balekai-700">Log in to balekai</h2>
        <p className="text-gray-500 text-sm mt-1">Enter your details to sign in to your account</p>
      </div>

      <Form {...form}>
        <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
          {/* Error Message */}
          {errorMessage && (
            <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-md text-sm">
              {errorMessage}
            </div>
          )}
          
          {/* Email */}
          <FormField
            control={form.control}
            name="email"
            render={({ field }) => (
              <FormItem>
                <FormLabel className="text-gray-700">Email</FormLabel>
                <FormControl>
                  <Input placeholder="you@example.com" {...field} className="balekai-input" />
                </FormControl>
                <FormMessage className="text-red-500" />
              </FormItem>
            )}
          />

          {/* Password */}
          <FormField
            control={form.control}
            name="password"
            render={({ field }) => (
              <FormItem>
                <FormLabel className="text-gray-700">Password</FormLabel>
                <FormControl>
                  <Input 
                    type="password" 
                    placeholder="Enter your password" 
                    {...field} 
                    className="balekai-input" 
                  />
                </FormControl>
                <FormMessage className="text-red-500" />
              </FormItem>
            )}
          />

          <Button 
            type="submit" 
            className="w-full balekai-button" 
            disabled={isLoading}
          >
            {isLoading ? "Signing in..." : "Sign in"}
          </Button>
        </form>
      </Form>

      {/* Google sign-in button removed */}

      <div className="mt-4 text-center">
        <p className="text-sm text-gray-600">
          Don&apos;t have an account?{" "}
          <Link href="/register" className="text-balekai-600 hover:text-balekai-700 font-medium">
            Sign up
          </Link>
        </p>
      </div>
    </div>
  )
}
