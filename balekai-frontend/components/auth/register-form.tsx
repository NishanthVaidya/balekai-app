"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { zodResolver } from "@hookform/resolvers/zod"
import { useForm } from "react-hook-form"
import Link from "next/link"
import * as z from "zod"
import api from "@/app/utils/api"
import { setTokens } from "@/app/utils/token"


import { Button } from "@/components/ui/button"
import {
  Form, FormControl, FormField, FormItem, FormLabel, FormMessage,
} from "@/components/ui/form"
import { Input } from "@/components/ui/input"
// import { signInWithGoogle } from "@/lib/firebase" // Google sign-in disabled

const formSchema = z.object({
  name: z.string().min(2, { message: "Name is required." }),
  email: z.string().email({ message: "Please enter a valid email." }),
  password: z.string().min(8, { message: "Password must be at least 8 characters." }),
})

export function RegisterForm() {
  const router = useRouter()
  const [isLoading, setIsLoading] = useState(false)
  const [errorMessage, setErrorMessage] = useState("")

  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    defaultValues: { name: "", email: "", password: "" },
  })

  const onSubmit = async (data: z.infer<typeof formSchema>) => {
    setIsLoading(true)
    setErrorMessage("") // Clear any previous error messages
    try {
      // Call backend register endpoint
      const response = await api.post("/auth/register", {
        name: data.name,
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
        localStorage.setItem("user", JSON.stringify({ name: data.name, email: data.email }))
      } else if (tokenData && tokenData.accessToken && tokenData.refreshToken) {
        // Tokens without user payload: keep minimal user as fallback
        setTokens(tokenData.accessToken, tokenData.refreshToken)
        localStorage.setItem("user", JSON.stringify({ name: data.name, email: data.email }))
      } else {
        throw new Error("Invalid token response format")
      }

      router.push("/boards")
    } catch (error: unknown) {
      const errorMsg = error instanceof Error ? error.message : 
        (error as { response?: { data?: string } })?.response?.data || "Registration failed. Please try again."
      setErrorMessage(errorMsg)
    } finally {
      setIsLoading(false)
    }
  }

  // Google signup functionality disabled
  // const handleGoogleSignup = async () => { ... }

  return (
    <div className="space-y-6">
      <Form {...form}>
        <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
          {/* Error Message */}
          {errorMessage && (
            <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-md text-sm">
              {errorMessage}
            </div>
          )}
          
          {/* Name */}
          <FormField
            control={form.control}
            name="name"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Name</FormLabel>
                <FormControl><Input placeholder="John Doe" {...field} /></FormControl>
                <FormMessage />
              </FormItem>
            )}
          />

          {/* Email */}
          <FormField
            control={form.control}
            name="email"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Email</FormLabel>
                <FormControl><Input placeholder="you@example.com" {...field} /></FormControl>
                <FormMessage />
              </FormItem>
            )}
          />

          {/* Password */}
          <FormField
            control={form.control}
            name="password"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Password</FormLabel>
                <FormControl><Input type="password" placeholder="********" {...field} /></FormControl>
                <FormMessage />
              </FormItem>
            )}
          />

          <Button type="submit" className="w-full" disabled={isLoading}>
            {isLoading ? "Signing up..." : "Sign up"}
          </Button>
          <div className="text-center">
            <Link href="/login" className="text-sm hover:text-brand underline underline-offset-4">
              Back to Login
            </Link>
          </div>

        </form>
      </Form>

      {/* Google sign-up button and divider removed */}
    </div>
  )
}
