"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { zodResolver } from "@hookform/resolvers/zod"
import { useForm } from "react-hook-form"
import * as z from "zod"
import Link from "next/link"

import { Button } from "@/components/ui/button"
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form"
import { Input } from "@/components/ui/input"
import { useToast } from "@/hooks/use-toast"
import { signInWithGoogle, auth } from "@/lib/firebase"
import { signInWithEmailAndPassword } from "firebase/auth"

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
      const userCredential = await signInWithEmailAndPassword(auth, data.email, data.password)
      const token = await userCredential.user.getIdToken()

      localStorage.setItem("token", token)
      localStorage.setItem("user", JSON.stringify({
        id: userCredential.user.uid,
        name: userCredential.user.displayName ?? data.email.split("@")[0],
        email: data.email,
      }))

      toast({ title: "Success", description: "Logged in successfully." })
      router.push("/boards")
    } catch (error: unknown) {
      toast({ title: "Login failed", description: typeof error === 'object' && error && 'message' in error ? (error as { message: string }).message : String(error), variant: "destructive" })
    } finally {
      setIsLoading(false)
    }
  }

  const handleGoogleLogin = async () => {
    try {
      const result = await signInWithGoogle()
      const user = result.user
      const token = await user.getIdToken()

      localStorage.setItem("token", token)
      localStorage.setItem("user", JSON.stringify({
        id: user.uid,
        name: user.displayName,
        email: user.email,
      }))

      toast({ title: "Success", description: "Logged in with Google." })
      router.push("/boards")
    } catch (err: unknown) {
      toast({ title: "Google login failed", description: typeof err === 'object' && err && 'message' in err ? (err as { message: string }).message : String(err), variant: "destructive" })
    }
  }

  return (
    <div className="trello-card">
      <div className="mb-6 text-center">
        <h2 className="text-2xl font-bold text-trello-700">Log in to Trello</h2>
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
                  <Input placeholder="you@example.com" {...field} className="trello-input" />
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
                <div className="flex justify-between items-center">
                  <FormLabel className="text-gray-700">Password</FormLabel>
                  <Link href="/forgot-password" className="text-xs trello-link">
                    Forgot password?
                  </Link>
                </div>
                <FormControl>
                  <Input type="password" placeholder="********" {...field} className="trello-input" />
                </FormControl>
                <FormMessage className="text-red-500" />
              </FormItem>
            )}
          />

          <Button type="submit" className="w-full h-10 mt-2 trello-button" disabled={isLoading}>
            {isLoading ? "Signing in..." : "Log in"}
          </Button>
        </form>
      </Form>

      <div className="mt-4">
        <Button
          onClick={handleGoogleLogin}
          variant="outline"
          className="w-full text-gray-800 bg-white border border-gray-300 hover:bg-gray-100"
        >
          Sign in with Google
        </Button>
      </div>


    </div>
  )
}
