"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { zodResolver } from "@hookform/resolvers/zod"
import { useForm } from "react-hook-form"
import Link from "next/link"
import * as z from "zod"
import api from "@/app/utils/api"


import { Button } from "@/components/ui/button"
import {
  Form, FormControl, FormField, FormItem, FormLabel, FormMessage,
} from "@/components/ui/form"
import { Input } from "@/components/ui/input"
import { useToast } from "@/hooks/use-toast"
import { signInWithGoogle } from "@/lib/firebase"

const formSchema = z.object({
  name: z.string().min(2, { message: "Name is required." }),
  email: z.string().email({ message: "Please enter a valid email." }),
  password: z.string().min(8, { message: "Password must be at least 8 characters." }),
})

export function RegisterForm() {
  const router = useRouter()
  const { toast } = useToast()
  const [isLoading, setIsLoading] = useState(false)

  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    defaultValues: { name: "", email: "", password: "" },
  })

  const onSubmit = async (data: z.infer<typeof formSchema>) => {
    setIsLoading(true)
    try {
      // Call backend register endpoint
      const response = await api.post("/auth/register", {
        name: data.name,
        email: data.email,
        password: data.password,
      })

      const token = response.data
      
      // Store the JWT token from backend
      localStorage.setItem("token", token)
      localStorage.setItem("user", JSON.stringify({
        name: data.name,
        email: data.email,
      }))

      router.push("/boards")
    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : 
        (error as { response?: { data?: string } })?.response?.data || "Registration failed. Please try again."
      toast({ 
        title: "Registration failed", 
        description: errorMessage, 
        variant: "destructive" 
      })
    } finally {
      setIsLoading(false)
    }
  }

  const handleGoogleSignup = async () => {
    setIsLoading(true)
    try {
      const result = await signInWithGoogle()
      const user = result.user
      const idToken = await user.getIdToken()

      // Store the Firebase ID token
      localStorage.setItem("token", idToken)
      localStorage.setItem(
        "user",
        JSON.stringify({
          id: user.uid,
          name: user.displayName || "User",
          email: user.email || "",
        })
      )

      // For Google users, skip backend registration - they'll be auto-created by FirebaseTokenFilter
      router.push("/boards")
    } catch (error: unknown) {
      const description =
        (error as { message?: string })?.message ||
        "Google sign-up failed. Please try again."
      toast({ title: "Sign-up failed", description, variant: "destructive" })
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="space-y-6">
      <Form {...form}>
        <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
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

      <div className="flex items-center justify-center">
        <div className="w-full border-t border-gray-300" />
        <span className="px-4 text-gray-500 text-sm">or</span>
        <div className="w-full border-t border-gray-300" />
      </div>


      <Button
        onClick={handleGoogleSignup}
        variant="outline"
        className="w-full text-gray-800 bg-white border border-gray-300 hover:bg-gray-100"
      >
        Continue with Google
      </Button>
    </div>
  )
}
