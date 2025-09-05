"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { zodResolver } from "@hookform/resolvers/zod"
import { useForm } from "react-hook-form"
import * as z from "zod"
import Link from "next/link"
import api from "@/app/utils/api"

import { Button } from "@/components/ui/button"
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form"
import { Input } from "@/components/ui/input"
import { useToast } from "@/hooks/use-toast"
import { signInWithGoogle } from "@/lib/firebase"

const formSchema = z.object({
  email: z.string().email({ message: "Please enter a valid email." }),
  password: z.string().min(8, { message: "Password must be at least 8 characters." }),
})

export function LoginForm() {
  const router = useRouter()
  const { toast } = useToast()
  const [isLoading, setIsLoading] = useState(false)

  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      email: "",
      password: "",
    },
  })

  const onSubmit = async (data: z.infer<typeof formSchema>) => {
    setIsLoading(true)
    try {
      // Call backend login endpoint
      const response = await api.post("/auth/login", {
        email: data.email,
        password: data.password,
        name: data.email.split("@")[0], // Use email prefix as name for login
      })

      const token = response.data
      
      // Store the JWT token from backend
      localStorage.setItem("token", token)
      localStorage.setItem("user", JSON.stringify({
        email: data.email,
        name: data.email.split("@")[0],
      }))

      toast({ title: "Success", description: "Logged in successfully." })
      router.push("/boards")
    } catch (error: unknown) {
      const errorMessage = (error as { response?: { data?: string } })?.response?.data || "Login failed. Please try again."
      toast({ 
        title: "Login failed", 
        description: errorMessage, 
        variant: "destructive" 
      })
    } finally {
      setIsLoading(false)
    }
  }

  const handleGoogleLogin = async () => {
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

      // For Google users, skip backend login - they'll be auto-created by FirebaseTokenFilter
      toast({ title: "Success", description: "Logged in with Google." })
      router.push("/boards")
    } catch (error: unknown) {
      const description =
        (error as { message?: string })?.message ||
        "Google login failed. Please try again."
      toast({ title: "Login failed", description, variant: "destructive" })
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="balekai-card">
      <div className="mb-6 text-center">
        <h2 className="text-2xl font-bold text-balekai-700">Log in to balekai</h2>
        <p className="text-gray-500 text-sm mt-1">Enter your details to sign in to your account</p>
      </div>

      <Form {...form}>
        <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
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

      <div className="mt-6">
        <Button 
          type="button" 
          variant="outline" 
          className="w-full" 
          onClick={handleGoogleLogin}
        >
          Continue with Google
        </Button>
      </div>

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
