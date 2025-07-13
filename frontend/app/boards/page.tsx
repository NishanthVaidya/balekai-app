"use client"

import { useEffect, useState, useRef } from "react"
import Link from "next/link"
import api from "../utils/api"
import { useRouter } from "next/navigation"
import { Edit, Save, X } from "lucide-react"
import { Navbar } from "@/components/navbar"

interface Board {
  id: number
  name: string
  ownerId: string
  isPrivate: boolean
}

const BoardsPage = () => {
  const [boards, setBoards] = useState<Board[]>([])
  const [newBoardName, setNewBoardName] = useState("")
  const [isPrivate, setIsPrivate] = useState(false)
  const [draggedId, setDraggedId] = useState<number | null>(null)
  const [currentUserId, setCurrentUserId] = useState("test-user") // Replace with real auth in production
  const [username, setUsername] = useState("User") // For the navbar
  const [sidebarOpen, setSidebarOpen] = useState(false)
  const [editingBoardId, setEditingBoardId] = useState<number | null>(null)
  const [editedBoardName, setEditedBoardName] = useState("")
  const editInputRef = useRef<HTMLInputElement>(null)
  const router = useRouter()

  useEffect(() => {
    const token = localStorage.getItem("token")
    const userData = localStorage.getItem("user")

    if (!token) {
      router.push("/login")
      return
    }

    try {
      // If we have user data, parse it
      if (userData) {
        const user = JSON.parse(userData)
        setUsername(user.name || "User")
        setCurrentUserId(user.id || "test-user")
      } else {
        // If no user data but we have token, set default values
        setUsername("User")
        setCurrentUserId("test-user")
      }
    } catch (err) {
      console.error("Failed to parse user data", err)
      // Even if parsing fails, don't redirect if we have a token
    }

    const fetchBoards = async () => {
      try {
        const res = await api.get("/boards")
        const filtered = res.data.filter((b: Board) => !b.isPrivate || b.ownerId === currentUserId)
        setBoards(filtered)
      } catch (err) {
        console.error("Failed to fetch boards", err)
      }
    }

    fetchBoards()
  }, [router, currentUserId])

  useEffect(() => {
    // Focus the edit input when it appears
    if (editingBoardId !== null && editInputRef.current) {
      editInputRef.current.focus()
    }
  }, [editingBoardId])

const handleCreateBoard = async () => {
  if (!newBoardName.trim()) return

  try {
    // Get user info from localStorage
    const userData = JSON.parse(localStorage.getItem("user") || "{}")

    await api.post("/boards", {
      name: newBoardName,
      ownerId: userData.id,     // fallback to currentUserId just in case
      ownerName: userData.name,        // send the owner's display name
      isPrivate,                                 // now correctly interpreted as a boolean
    })

    // Refresh the board list
    const res = await api.get("/boards")
    const filteredBoards = res.data.filter(
      (b: Board) => !b.isPrivate || b.ownerId === (userData.id || currentUserId)
    )
    setBoards(filteredBoards)

    // Reset form
    setNewBoardName("")
    setIsPrivate(false)
  } catch (err) {
    console.error("Failed to create board:", err)
  }
}


  const handleDeleteBoard = async (id: number) => {
    const confirmDelete = window.confirm("Are you sure you want to delete this board?")
    if (!confirmDelete) return

    try {
      await api.delete(`/boards/${id}`)
      setBoards((prev) => prev.filter((b) => b.id !== id))
    } catch (err) {
      console.error("Failed to delete board:", err)
    }
  }

  const handleEditBoard = (board: Board) => {
    setEditingBoardId(board.id)
    setEditedBoardName(board.name)
  }

  const handleSaveEdit = async () => {
    if (!editedBoardName.trim() || editingBoardId === null) {
      setEditingBoardId(null)
      return
    }

    try {
      const boardToUpdate = boards.find((b) => b.id === editingBoardId)
      if (!boardToUpdate) return

      await api.put(`/boards/${editingBoardId}`, {
        ...boardToUpdate,
        name: editedBoardName,
      })

      setBoards((prev) => prev.map((b) => (b.id === editingBoardId ? { ...b, name: editedBoardName } : b)))
      setEditingBoardId(null)
    } catch (err) {
      console.error("Failed to update board name:", err)
    }
  }

  const handleCancelEdit = () => {
    setEditingBoardId(null)
  }

  const handleDragStart = (id: number) => {
    setDraggedId(id)
  }

  const handleDrop = (targetId: number) => {
    if (draggedId === null || draggedId === targetId) return

    const draggedIndex = boards.findIndex((b) => b.id === draggedId)
    const targetIndex = boards.findIndex((b) => b.id === targetId)

    const updated = [...boards]
    const [moved] = updated.splice(draggedIndex, 1)
    updated.splice(targetIndex, 0, moved)

    setBoards(updated)
    setDraggedId(null)
  }

  const getVisibilityBadgeClass = (isPrivate: boolean) => {
    return isPrivate ? "bg-purple-100 text-purple-800" : "bg-green-100 text-green-800"
  }

  const toggleSidebar = () => {
    setSidebarOpen(!sidebarOpen)
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 flex flex-col">
      {/* Top Navbar with sidebar toggle */}
      <Navbar username={username} sidebarOpen={sidebarOpen} onSidebarToggle={toggleSidebar} title="Your Boards" />

      <div className="flex flex-1">
        {/* Collapsible Sidebar */}
        <div
          className={`bg-white border-r border-gray-200 transition-all duration-300 ease-in-out ${
            sidebarOpen ? "w-64" : "w-0 overflow-hidden"
          }`}
        >
          <div className="p-4 border-b border-gray-200">
            <h2 className="font-bold text-gray-800">All Boards</h2>
          </div>
          <div className="p-2">
            {boards.map((board) => (
              <div
                key={board.id}
                className="p-2 mb-1 rounded hover:bg-gray-100 cursor-pointer flex items-center"
                draggable
                onDragStart={() => handleDragStart(board.id)}
                onDragOver={(e) => e.preventDefault()}
                onDrop={() => handleDrop(board.id)}
              >
                <Link href={`/boards/${board.id}`} className="flex-1 truncate text-gray-800 font-medium">
                  {board.name}
                </Link>
                <span className={`ml-2 px-1.5 py-0.5 text-xs rounded-full ${getVisibilityBadgeClass(board.isPrivate)}`}>
                  {board.isPrivate ? "🔒" : "🌐"}
                </span>
              </div>
            ))}
          </div>
        </div>

        {/* Main Content */}
        <div className="flex-1">
          <main className="max-w-7xl mx-auto p-6">
            {/* Create Board Form */}
            <div className="bg-white rounded-lg shadow-md border border-gray-200 p-4 mb-6">
              <h2 className="text-lg font-medium text-gray-900 mb-4">Create New Board</h2>
              <div className="flex flex-col sm:flex-row gap-3">
                <input
                  type="text"
                  placeholder="Board name"
                  value={newBoardName}
                  onChange={(e) => setNewBoardName(e.target.value)}
                  className="flex-1 p-2 border border-gray-300 rounded-md text-sm text-gray-800 placeholder-gray-500 focus:ring-trello-500 focus:border-trello-500"
                />
                <div className="flex items-center">
                  <label className="inline-flex items-center mr-4">
                    <input
                      type="checkbox"
                      checked={isPrivate}
                      onChange={(e) => setIsPrivate(e.target.checked)}
                      className="rounded border-gray-300 text-trello-600 shadow-sm focus:border-trello-300 focus:ring focus:ring-trello-200 focus:ring-opacity-50 mr-2"
                    />
                    <span className="text-sm text-gray-700">Private</span>
                  </label>
                  <button
                    onClick={handleCreateBoard}
                    className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md text-sm font-medium transition-colors duration-200"
                  >
                    Create Board
                  </button>
                </div>
              </div>
            </div>

            {/* Boards Grid */}
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
              {boards.map((board) => (
                <div
                  key={board.id}
                  className="bg-white rounded-lg shadow-md border border-gray-200 relative group transition-all duration-200 hover:shadow-lg"
                  draggable
                  onDragStart={() => handleDragStart(board.id)}
                  onDragOver={(e) => e.preventDefault()}
                  onDrop={() => handleDrop(board.id)}
                >
                  <div className="p-4">
                    <div className="mb-3 flex justify-between items-center">
                      {editingBoardId === board.id ? (
                        <div className="flex items-center flex-1">
                          <input
                            ref={editInputRef}
                            type="text"
                            value={editedBoardName}
                            onChange={(e) => setEditedBoardName(e.target.value)}
                            className="flex-1 p-1 border border-gray-300 rounded-md text-lg font-medium text-gray-800"
                            onKeyDown={(e) => {
                              if (e.key === "Enter") handleSaveEdit()
                              if (e.key === "Escape") handleCancelEdit()
                            }}
                          />
                          <button
                            onClick={handleSaveEdit}
                            className="ml-2 text-green-600 hover:text-green-800"
                            title="Save"
                          >
                            <Save size={18} />
                          </button>
                          <button
                            onClick={handleCancelEdit}
                            className="ml-1 text-gray-500 hover:text-gray-700"
                            title="Cancel"
                          >
                            <X size={18} />
                          </button>
                        </div>
                      ) : (
                        <div className="flex items-center flex-1">
                          <Link
                            href={`/boards/${board.id}`}
                            className="text-xl font-medium text-gray-900 hover:text-trello-600 transition-colors"
                          >
                            {board.name}
                          </Link>
                          <button
                            onClick={() => handleEditBoard(board)}
                            className="ml-2 text-gray-400 hover:text-gray-700 opacity-0 group-hover:opacity-100 transition-opacity"
                            title="Edit board name"
                          >
                            <Edit size={16} />
                          </button>
                        </div>
                      )}
                      <div className="flex-shrink-0 ml-2">
                        <span
                          className={`inline-flex items-center px-2 py-1 text-xs rounded-full ${getVisibilityBadgeClass(board.isPrivate)}`}
                        >
                          <span className="mr-1 text-xs">{board.isPrivate ? "🔒" : "🌐"}</span>
                          {board.isPrivate ? "Private" : "Public"}
                        </span>
                      </div>
                    </div>

                    {!editingBoardId && (
                      <div className="mt-4">
                        <Link
                          href={`/boards/${board.id}`}
                          className="text-trello-600 hover:text-trello-800 text-sm font-medium"
                        >
                          Open Board →
                        </Link>
                      </div>
                    )}
                  </div>

                  {/* Delete Button - Moved to top right with more spacing */}
                  <button
                    onClick={(e) => {
                      e.preventDefault()
                      e.stopPropagation()
                      handleDeleteBoard(board.id)
                    }}
                    className="absolute top-2 right-2 text-gray-400 hover:text-red-500 p-1 rounded-full hover:bg-gray-100 opacity-0 group-hover:opacity-100 transition-opacity"
                    title="Delete board"
                  >
                    <span className="text-sm">×</span>
                  </button>
                </div>
              ))}
            </div>

            {boards.length === 0 && (
              <div className="bg-white/80 border border-dashed border-gray-300 rounded-lg p-8 flex flex-col items-center justify-center text-gray-500 mt-8">
                <p className="text-lg mb-2">No boards found</p>
                <p className="text-sm">Create your first board to get started</p>
              </div>
            )}
          </main>
        </div>
      </div>
    </div>
  )
}

export default BoardsPage
