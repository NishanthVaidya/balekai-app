"use client"

import type React from "react"

import { useEffect, useState } from "react"
import { useParams } from "next/navigation"
import Link from "next/link"
import api from "../../utils/api"
import { ChevronLeft, ArrowLeft } from "lucide-react"
import { Navbar } from "@/components/navbar"

interface Card {
  id: number
  title: string
  currentState: string
  label: string
  assignedUser?: { id: string; name: string }
  stateHistory?: string[] // ✅ Added stateHistory field
}

interface List {
  id: number
  name: string
  cards: Card[]
}

interface Board {
  id: number
  name: string
  lists: List[]
  ownerName?: string
}

interface UserType {
  id: string
  name: string
}

interface BoardSummary {
  id: number
  name: string
  ownerId: string
  isPrivate: boolean
}

export default function BoardPage() {
  const params = useParams()
  const boardId = params?.boardId
  const [board, setBoard] = useState<Board | null>(null)
  const [allBoards, setAllBoards] = useState<BoardSummary[]>([])
  const [newListName, setNewListName] = useState("")
  const [newCardTitles, setNewCardTitles] = useState<Record<number, string>>({})
  const [draggedCard, setDraggedCard] = useState<{ card: Card; fromListId: number } | null>(null)
  const [showAddList, setShowAddList] = useState(false)
  const [tempIdCounter, setTempIdCounter] = useState(-1) // Negative IDs for temporary items
  const [sidebarOpen, setSidebarOpen] = useState(false) // Changed to false to keep sidebar collapsed by default
  const [currentUserId] = useState("test-user") // Replace with real auth in production

  const [selectedCard, setSelectedCard] = useState<Card | null>(null)
  const [cardHistory, setCardHistory] = useState<string[]>([])
  const [allUsers, setAllUsers] = useState<UserType[]>([])

  useEffect(() => {
    const fetchBoard = async () => {
      try {
        const res = await api.get(`/boards/${boardId}`)
        setBoard(res.data)
      } catch (err) {
        console.error("Failed to fetch board details:", err)
      }
    }
    if (boardId) fetchBoard()
  }, [boardId])

  useEffect(() => {
    const fetchAllBoards = async () => {
      try {
        const res = await api.get("/boards")
        // Filter boards to only show public boards or private boards owned by current user
        const filteredBoards = res.data.filter(
          (board: BoardSummary) => !board.isPrivate || board.ownerId === currentUserId,
        )
        setAllBoards(filteredBoards)
      } catch (err) {
        console.error("Failed to fetch all boards:", err)
      }
    }
    fetchAllBoards()
  }, [currentUserId])

  useEffect(() => {
    const fetchUsers = async () => {
      try {
        const res = await api.get("/users")
        // ✅ Ensure user data is properly formatted
        const users = res.data.map((user: { id: string | number; name?: string }) => ({
          id: String(user.id), // Ensure ID is string
          name: user.name || "Unknown User"
        }))
        setAllUsers(users)
      } catch (err) {
        console.error("Failed to fetch users:", err)
        // Set empty array on error
        setAllUsers([])
      }
    }
    fetchUsers()
  }, [])

  const handleAssignUser = async (userId: string | number) => {
    if (!selectedCard) return
    
    // ✅ Add validation to prevent API calls with temporary card IDs
    if (!isValidCardId(selectedCard.id)) {
      console.warn("Cannot assign user to temporary card. Please save the card first.")
      alert("Cannot assign user to unsaved card. Please save the card first.")
      return
    }
    
    // Convert to string to ensure compatibility with backend
    const stringUserId = String(userId)
    
    try {
      await api.put(`/cards/${selectedCard.id}/assign?userId=${stringUserId}`)
      const assignedUser = stringUserId ? allUsers.find((u) => u.id === stringUserId) : null
      
      // ✅ Update state history
      const assignmentEntry = assignedUser 
        ? `Assigned to ${assignedUser.name} at ${new Date().toLocaleString()}`
        : `Unassigned at ${new Date().toLocaleString()}`
      
      const updatedCard = { 
        ...selectedCard, 
        assignedUser: assignedUser || undefined,
        stateHistory: [...(selectedCard.stateHistory || []), assignmentEntry]
      }
      
      setSelectedCard(updatedCard)
      
      // ✅ Update card history display
      setCardHistory([...(selectedCard.stateHistory || []), assignmentEntry])

      // Update the board state to reflect the change
      if (board) {
        const updatedBoard = { ...board }
        updatedBoard.lists = updatedBoard.lists.map((list) => ({
          ...list,
          cards: list.cards.map((card) =>
            card.id === selectedCard.id ? updatedCard : card,
          ),
        }))
        setBoard(updatedBoard)
      }
    } catch (err) {
      console.error("Failed to assign user:", err)
      alert("Failed to assign user. Please try again.")
    }
  }

  const handleSaveMetadata = async () => {
    if (!selectedCard) return
    try {
      await api.put(`/cards/${selectedCard.id}/update-metadata`, {
        title: selectedCard.title,
        label: selectedCard.label,
      })

      const updatedBoard = { ...board! }
      updatedBoard.lists = updatedBoard.lists.map((list) => {
        return {
          ...list,
          cards: list.cards.map((c) => (c.id === selectedCard.id ? { ...c, ...selectedCard } : c)),
        }
      })

      setBoard(updatedBoard)
      setSelectedCard(null) // ✅ Closes the drawer after saving
    } catch (err) {
      console.error("Failed to save metadata:", err)
      // Optimistically update UI even if API call fails
      if (board && selectedCard) {
        const updatedBoard = { ...board }
        updatedBoard.lists = updatedBoard.lists.map((list) => {
          return {
            ...list,
            cards: list.cards.map((c) => (c.id === selectedCard.id ? { ...c, ...selectedCard } : c)),
          }
        })
        setBoard(updatedBoard)
        setSelectedCard(null)
      }
    }
  }

  const handleDeleteCard = async () => {
    if (!selectedCard || !board) return

    try {
      // Only try API call if it's not a temporary card (positive ID)
      if (selectedCard.id > 0) {
        await api.delete(`/cards/${selectedCard.id}`)
      }

      // Update the board state to remove the card
      const updatedBoard = { ...board }
      updatedBoard.lists = updatedBoard.lists.map((list) => ({
        ...list,
        cards: list.cards.filter((card) => card.id !== selectedCard.id),
      }))

      setBoard(updatedBoard)
      setSelectedCard(null) // Close the drawer after deleting
    } catch (err) {
      console.error("Failed to delete card:", err)
      // Optimistically update UI even if API call fails
      const updatedBoard = { ...board }
      updatedBoard.lists = updatedBoard.lists.map((list) => ({
        ...list,
        cards: list.cards.filter((card) => card.id !== selectedCard.id),
      }))

      setBoard(updatedBoard)
      setSelectedCard(null)
    }
  }

  // ✅ Helper function to check if a card ID is valid for API calls
  const isValidCardId = (id: number): boolean => {
    return id > 0 && !isNaN(id) && isFinite(id)
  }

  const handleStateChange = async (newState: string) => {
    if (!selectedCard || !board) return

    // ✅ Add validation to prevent API calls with temporary card IDs
    if (!isValidCardId(selectedCard.id)) {
      console.warn("Cannot change state for temporary card. Please save the card first.")
      alert("Cannot change state for unsaved card. Please save the card first.")
      return
    }

    try {
      await api.put(`/cards/${selectedCard.id}/transition?newState=${newState}`)
      const targetList = board.lists.find((l) => l.name.toLowerCase() === newState.toLowerCase())
      if (!targetList) return

      await api.put(`/cards/${selectedCard.id}/move?listId=${targetList.id}`)

      // ✅ Update state history
      const stateHistoryEntry = `${selectedCard.currentState} → ${newState} at ${new Date().toLocaleString()}`
      
      const updatedBoard = { ...board }
      updatedBoard.lists = updatedBoard.lists.map((list) => {
        if (list.cards.some((c) => c.id === selectedCard.id)) {
          return { ...list, cards: list.cards.filter((c) => c.id !== selectedCard.id) }
        }
        if (list.id === targetList.id) {
          const updatedCard = { 
            ...selectedCard, 
            currentState: newState,
            stateHistory: [...(selectedCard.stateHistory || []), stateHistoryEntry]
          }
          return { ...list, cards: [...list.cards, updatedCard] }
        }
        return list
      })

      setBoard(updatedBoard)
      setSelectedCard({ 
        ...selectedCard, 
        currentState: newState,
        stateHistory: [...(selectedCard.stateHistory || []), stateHistoryEntry]
      })
      
      // ✅ Update card history display
      setCardHistory([...(selectedCard.stateHistory || []), stateHistoryEntry])
    } catch (err) {
      console.error("Failed to change card state:", err)
      alert("Failed to change card state. Please try again.")
    }
  }

  const openCardHistory = async (card: Card) => {
    try {
      // ✅ Use the stateHistory from the card data if available, otherwise fetch from API
      if (card.stateHistory && card.stateHistory.length > 0) {
        setCardHistory(card.stateHistory)
      } else if (isValidCardId(card.id)) {
        // Only fetch from API for valid card IDs
        const res = await api.get(`/cards/${card.id}/history`)
        setCardHistory(res.data)
      } else {
        // For temporary cards, show empty history with a note
        setCardHistory(["This is a temporary card. Save it to view activity history."])
      }
      setSelectedCard(card)
    } catch (err) {
      console.error("Failed to fetch card history:", err)
      // If API fails, still open the card details with empty history
      setCardHistory([])
      setSelectedCard(card)
    }
  }

  const handleAddList = () => {
    if (!newListName.trim() || !board) return

    // Skip API call entirely and just create a temporary list
    const tempId = tempIdCounter
    setTempIdCounter(tempId - 1)

    const newList: List = {
      id: tempId,
      name: newListName,
      cards: [],
    }

    setBoard({
      ...board,
      lists: [...board.lists, newList],
    })
    setNewListName("")
    setShowAddList(false)
  }

  const handleAddCard = async (listId: number) => {
    const cardTitle = newCardTitles[listId]
    if (!cardTitle?.trim() || !board) return

    try {
      const res = await api.post(`/cards`, {
        title: cardTitle,
        label: "Default",
        currentState: "To Do",
        list: { id: listId },
      })

      const newCard = res.data

      const updatedBoard = { ...board }
      updatedBoard.lists = updatedBoard.lists.map((list) =>
        list.id === listId ? { ...list, cards: [...list.cards, newCard] } : list,
      )

      setBoard(updatedBoard)
      setNewCardTitles((prev) => ({ ...prev, [listId]: "" }))
    } catch (err) {
      console.error("❌ Failed to add new card:", err)

      // Create a temporary card with a negative ID
      const tempId = tempIdCounter
      setTempIdCounter(tempId - 1)

      const list = board.lists.find((l) => l.id === listId)
      if (!list) return

      const newCard: Card = {
        id: tempId,
        title: cardTitle,
        currentState: list.name,
        label: "Default",
      }

      const updatedBoard = { ...board }
      updatedBoard.lists = updatedBoard.lists.map((list) =>
        list.id === listId ? { ...list, cards: [...list.cards, newCard] } : list,
      )

      setBoard(updatedBoard)
      setNewCardTitles((prev) => ({ ...prev, [listId]: "" }))
    }
  }

  const handleDragStart = (card: Card, listId: number) => {
    setDraggedCard({ card, fromListId: listId })
  }

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault()
  }

  const handleDrop = async (targetListId: number) => {
    if (!draggedCard || !board) return

    if (draggedCard.fromListId === targetListId) {
      setDraggedCard(null)
      return
    }

    try {
      const targetList = board.lists.find((l) => l.id === targetListId)
      if (!targetList) return

      // Only try API call if it's not a temporary card (positive ID)
      if (draggedCard.card.id > 0) {
        // Update both the list and the state
        await api.put(`/cards/${draggedCard.card.id}/move?listId=${targetListId}`)
        await api.put(`/cards/${draggedCard.card.id}/transition?newState=${targetList.name}`)
      }

      const updatedBoard = { ...board }
      updatedBoard.lists = updatedBoard.lists.map((list) => {
        if (list.id === draggedCard.fromListId) {
          return {
            ...list,
            cards: list.cards.filter((c) => c.id !== draggedCard.card.id),
          }
        }
        if (list.id === targetListId) {
          return {
            ...list,
            cards: [...list.cards, { ...draggedCard.card, currentState: targetList.name }],
          }
        }
        return list
      })

      setBoard(updatedBoard)
      setDraggedCard(null)
    } catch (err) {
      console.error("Failed to move card:", err)

      // Update UI anyway for better UX
      const targetList = board.lists.find((l) => l.id === targetListId)
      if (!targetList) return

      const updatedBoard = { ...board }
      updatedBoard.lists = updatedBoard.lists.map((list) => {
        if (list.id === draggedCard.fromListId) {
          return {
            ...list,
            cards: list.cards.filter((c) => c.id !== draggedCard.card.id),
          }
        }
        if (list.id === targetListId) {
          return {
            ...list,
            cards: [...list.cards, { ...draggedCard.card, currentState: targetList.name }],
          }
        }
        return list
      })

      setBoard(updatedBoard)
      setDraggedCard(null)
    }
  }

  // Function to determine label color based on label text
  const getLabelColor = (label: string) => {
    const labelLower = label.toLowerCase()
    if (labelLower.includes("bug") || labelLower.includes("error")) {
      return "bg-red-100 text-red-800"
    } else if (labelLower.includes("feature")) {
      return "bg-green-100 text-green-800"
    } else if (labelLower.includes("improvement")) {
      return "bg-purple-100 text-purple-800"
    } else if (labelLower.includes("documentation")) {
      return "bg-blue-100 text-blue-800"
    } else if (labelLower === "default") {
      return "bg-gray-100 text-gray-800"
    } else {
      return "bg-indigo-100 text-indigo-800"
    }
  }

  // Function to determine visibility badge class
  const getVisibilityBadgeClass = (isPrivate: boolean) => {
    return isPrivate ? "bg-purple-100 text-purple-800" : "bg-green-100 text-green-800"
  }

  // Add a function to handle list deletion
  const handleDeleteList = (listId: number) => {
    if (!board) return

    // Remove the list from the board
    const updatedBoard = { ...board }
    updatedBoard.lists = updatedBoard.lists.filter((list) => list.id !== listId)
    setBoard(updatedBoard)
  }

  // Add a constant for standard list names
  const STANDARD_LISTS = ["To Do", "In Progress", "Blocked", "Review", "Done"]

  if (!board)
    return (
      <div className="flex items-center justify-center min-h-screen bg-gray-50">
        <div className="flex flex-col items-center">
          <div className="w-16 h-16 border-4 border-t-blue-500 border-blue-200 rounded-full animate-spin"></div>
          <p className="mt-4 text-xl font-medium text-gray-700">Loading board...</p>
        </div>
      </div>
    )

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 flex">
      {/* Collapsible Sidebar */}
      <div
        className={`bg-white border-r border-gray-200 transition-all duration-300 ease-in-out ${
          sidebarOpen ? "w-64" : "w-0 overflow-hidden"
        }`}
      >
        <div className="p-4 border-b border-gray-200 flex justify-between items-center">
          <h2 className="font-bold text-gray-800">All Boards</h2>
          <button onClick={() => setSidebarOpen(false)} className="text-gray-500 hover:text-gray-700">
            <ChevronLeft size={18} />
          </button>
        </div>
        <div className="p-2">
          <Link href="/boards" className="flex items-center p-2 mb-2 text-gray-800 hover:bg-gray-100 rounded-md">
            <ArrowLeft size={16} className="mr-2" />
            <span className="font-medium">Back to All Boards</span>
          </Link>

          <div className="mt-4 mb-2 px-2">
            <h3 className="text-xs uppercase tracking-wider text-gray-500 font-semibold">Your Boards</h3>
          </div>

          {allBoards.map((boardItem) => (
            <Link
              key={boardItem.id}
              href={`/boards/${boardItem.id}`}
              className={`block p-2 mb-1 rounded text-gray-800 font-medium hover:bg-gray-100 ${
                boardItem.id === Number(boardId) ? "bg-indigo-50 text-indigo-700" : ""
              }`}
            >
              <div className="flex items-center justify-between">
                <span className="truncate">{boardItem.name}</span>
                <span
                  className={`ml-2 px-1.5 py-0.5 text-xs rounded-full ${getVisibilityBadgeClass(boardItem.isPrivate)}`}
                >
                  {boardItem.isPrivate ? "🔒" : "🌐"}
                </span>
              </div>
            </Link>
          ))}
        </div>
      </div>

      {/* Main Content */}
      <div className="flex-1">
        {/* Top Navbar with sidebar toggle */}
        <Navbar
          username={board.ownerName || "User"}
          sidebarOpen={sidebarOpen}
          onSidebarToggle={() => setSidebarOpen(!sidebarOpen)}
          title={board.name}
        />

        <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6 pb-6">
            {board.lists.map((list) => (
              <div
                key={list.id}
                className={`bg-white rounded-lg shadow-md border border-gray-200 flex flex-col transition-all duration-200 ${
                  draggedCard ? "ring-2 ring-offset-2 ring-indigo-200" : ""
                }`}
                onDragOver={handleDragOver}
                onDrop={() => handleDrop(list.id)}
              >
                <div className="p-4 border-b border-gray-200 bg-gray-50 rounded-t-lg">
                  <div className="flex items-center justify-between">
                    <h3 className="font-medium text-gray-900">{list.name}</h3>
                    <div className="flex items-center gap-2">
                      <span className="bg-gray-200 text-gray-700 text-xs font-medium px-2 py-0.5 rounded-full">
                        {list.cards.length}
                      </span>
                      {!STANDARD_LISTS.includes(list.name) && (
                        <button
                          onClick={() => handleDeleteList(list.id)}
                          className="text-gray-400 hover:text-red-500 p-1 rounded-full hover:bg-gray-100"
                          title="Delete list"
                        >
                          <span className="text-sm">×</span>
                        </button>
                      )}
                    </div>
                  </div>
                </div>

                <div className="p-3 flex-1 overflow-y-auto max-h-[calc(100vh-250px)]">
                  {list.cards.map((card) => (
                    <div
                      key={card.id}
                      className={`bg-white border border-gray-200 p-3 rounded-md mb-2 shadow-sm hover:shadow cursor-pointer transform transition-transform duration-100 ${
                        draggedCard?.card.id === card.id ? "opacity-50" : "hover:-translate-y-1"
                      }`}
                      onClick={() => openCardHistory(card)}
                      draggable
                      onDragStart={() => handleDragStart(card, list.id)}
                    >
                      <div className="text-sm font-medium text-gray-900 mb-2">{card.title}</div>

                      <div className="flex items-center justify-between flex-wrap gap-1">
                        {card.label && (
                          <span
                            className={`inline-flex items-center px-2 py-1 text-xs rounded-full ${getLabelColor(card.label)}`}
                          >
                            <span className="mr-1 text-xs">🏷️</span>
                            {card.label}
                          </span>
                        )}

                        <span className="inline-flex items-center px-2 py-1 text-xs rounded-full bg-blue-100 text-blue-800">
                          <span className="mr-1 text-xs">📋</span>
                          {card.currentState}
                        </span>

                        {card.assignedUser && (
                          <span className="inline-flex items-center text-xs text-gray-500 bg-gray-100 px-2 py-1 rounded-full">
                            <span className="mr-1 text-xs">👤</span>
                            {card.assignedUser.name}
                          </span>
                        )}
                      </div>

                      {/* Card ID indicator for debugging */}
                      {card.id < 0 && <div className="mt-2 text-xs text-gray-400">Temporary card</div>}
                    </div>
                  ))}

                  {/* Only show "Add Card" for "To Do" list */}
                  {list.name === "To Do" && (
                    <div className="mt-3">
                      <div className="mb-2">
                        <input
                          type="text"
                          placeholder="Add a card..."
                          className="w-full p-2 border border-gray-300 rounded-md text-sm text-gray-800 placeholder-gray-500 focus:ring-indigo-500 focus:border-indigo-500"
                          value={newCardTitles[list.id] || ""}
                          onChange={(e) => setNewCardTitles({ ...newCardTitles, [list.id]: e.target.value })}
                          onKeyDown={(e) => {
                            if (e.key === "Enter") handleAddCard(list.id)
                          }}
                        />
                      </div>
                      <button
                        onClick={() => handleAddCard(list.id)}
                        className="w-full bg-indigo-50 hover:bg-indigo-100 text-indigo-700 py-2 rounded-md text-sm font-medium transition-colors duration-200"
                      >
                        + Add Card
                      </button>
                    </div>
                  )}
                </div>
              </div>
            ))}

            {showAddList ? (
              <div className="bg-white rounded-lg shadow-md border border-gray-200 p-4">
                <input
                  type="text"
                  placeholder="Enter list title..."
                  className="w-full p-2 border border-gray-300 rounded-md mb-3 text-gray-800 placeholder-gray-500 focus:ring-indigo-500 focus:border-indigo-500"
                  value={newListName}
                  onChange={(e) => setNewListName(e.target.value)}
                  onKeyDown={(e) => {
                    if (e.key === "Enter") handleAddList()
                  }}
                  autoFocus
                />
                <div className="flex space-x-2">
                  <button
                    onClick={handleAddList}
                    className="flex-1 bg-indigo-600 hover:bg-indigo-700 text-white px-3 py-2 rounded-md text-sm font-medium transition-colors duration-200"
                  >
                    Add List
                  </button>
                  <button
                    onClick={() => {
                      setShowAddList(false)
                      setNewListName("")
                    }}
                    className="flex-1 bg-gray-200 hover:bg-gray-300 text-gray-700 px-3 py-2 rounded-md text-sm font-medium transition-colors duration-200"
                  >
                    Cancel
                  </button>
                </div>
              </div>
            ) : (
              <button
                onClick={() => setShowAddList(true)}
                className="bg-white/80 hover:bg-white border border-dashed border-gray-300 rounded-lg p-4 flex items-center justify-center text-gray-500 hover:text-gray-700 h-24 transition-all duration-200 hover:border-indigo-300"
              >
                <span className="text-lg mr-2">+</span>
                <span className="font-medium">Add another list</span>
              </button>
            )}
          </div>
        </main>

        {/* Card Details Sidebar */}
        {selectedCard && (
          <>
            {/* Overlay */}
            <div
              className="fixed inset-0 bg-black/20 backdrop-blur-sm z-40"
              onClick={() => setSelectedCard(null)}
            ></div>

            {/* Sidebar */}
            <div
              className={`fixed top-0 right-0 w-full sm:w-[450px] h-full bg-white shadow-2xl p-6 z-50 overflow-y-auto transition-transform duration-300 ease-in-out ${
                selectedCard ? "translate-x-0" : "translate-x-full"
              }`}
            >
              <div className="flex justify-between items-center mb-6">
                <h2 className="text-xl font-bold text-gray-900">Card Details</h2>
                <button
                  onClick={() => setSelectedCard(null)}
                  className="text-gray-500 hover:text-gray-700 p-1 rounded-full hover:bg-gray-100"
                >
                  <span className="text-xl">&times;</span>
                </button>
              </div>

              <div className="space-y-6">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Title</label>
                  <input
                    type="text"
                    value={selectedCard.title}
                    onChange={(e) => setSelectedCard({ ...selectedCard, title: e.target.value })}
                    className="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm p-2 border text-gray-800"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Label</label>
                  <input
                    type="text"
                    value={selectedCard.label}
                    onChange={(e) => setSelectedCard({ ...selectedCard, label: e.target.value })}
                    className="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm p-2 border text-gray-800"
                  />
                  <div className="mt-2 flex flex-wrap gap-2">
                    {["Bug", "Feature", "Improvement", "Documentation", "Default"].map((label) => (
                      <button
                        key={label}
                        onClick={() => setSelectedCard({ ...selectedCard, label })}
                        className={`px-2 py-1 text-xs rounded-full ${getLabelColor(label)} transition-colors duration-200`}
                      >
                        {label}
                      </button>
                    ))}
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">State</label>
                  <select
                    className="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm p-2 border text-gray-800"
                    value={selectedCard.currentState}
                    onChange={(e) => handleStateChange(e.target.value)}
                  >
                    {board.lists.map((list) => (
                      <option key={list.id} value={list.name}>
                        {list.name}
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Assigned To</label>
                  <select
                    className="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm p-2 border text-gray-800"
                    value={selectedCard.assignedUser?.id || ""}
                    onChange={(e) => handleAssignUser(e.target.value)}
                  >
                    <option value="">-- Unassigned --</option>
                    {allUsers.map((user) => (
                      <option key={user.id} value={user.id}>
                        {user.name}
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <h3 className="text-sm font-medium text-gray-700 mb-2">Activity Log</h3>
                  <div className="bg-gray-50 rounded-md p-3 max-h-48 overflow-y-auto border border-gray-200">
                    {cardHistory.length > 0 ? (
                      <ul className="space-y-2">
                        {cardHistory.map((entry, idx) => (
                          <li key={idx} className="text-sm text-gray-600 flex items-start">
                            <span className="text-gray-400 mr-2">•</span>
                            <span>{entry}</span>
                          </li>
                        ))}
                      </ul>
                    ) : (
                      <p className="text-sm text-gray-500 italic">No activity recorded yet.</p>
                    )}
                  </div>
                </div>

                {/* Card ID indicator for debugging */}
                {selectedCard.id < 0 && (
                  <div className="text-xs text-gray-400 bg-gray-100 p-2 rounded-md">
                    This is a temporary card that exists only in the frontend.
                  </div>
                )}

                <div className="pt-4 border-t border-gray-200">
                  <button
                    onClick={handleSaveMetadata}
                    className="w-full bg-indigo-600 text-white py-2 px-4 rounded-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 transition-colors duration-200"
                  >
                    Save Changes
                  </button>
                  <button
                    onClick={handleDeleteCard}
                    className="w-full mt-2 bg-red-600 text-white py-2 px-4 rounded-md hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 transition-colors duration-200"
                  >
                    Delete Card
                  </button>
                </div>
              </div>
            </div>
          </>
        )}
      </div>
    </div>
  )
}
