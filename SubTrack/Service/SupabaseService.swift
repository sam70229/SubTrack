//
//  SupabaseService.swift
//  SubTrack
//
//  Created by Sam on 2025/5/27.
//
import Foundation
import Supabase


class SupabaseService {
    static let shared = SupabaseService()
    
    let client: SupabaseClient
    
    private init() {
        guard
          let urlString = Bundle.main.object(forInfoDictionaryKey: "Supabase url") as? String,
          let key = Bundle.main.object(forInfoDictionaryKey: "Supabase key") as? String,
          let url = URL(string: "https://\(urlString)")
        else {
          fatalError("Missing or invalid Supabase configuration")
        }
        
        client = SupabaseClient(supabaseURL: url, supabaseKey: key)

    }
}


