//
//  SupabaseService.swift
//  Road Tribe
//

import Foundation
import Supabase

/// Shared Supabase client. Use `supabase.auth`, `supabase.from(...)`, etc.
let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://gbhbcyswjcgztcubaduw.supabase.co")!,
    supabaseKey: "sb_publishable_w0ss0rTv8XuljgLWzfcfLA_6unbaa0J"
)
