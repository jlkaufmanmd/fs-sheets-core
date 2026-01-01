//
//  CharacterSheetApp.swift
//  CharacterSheet
//
//  Created by Jacob Kaufman on 12/30/25.
//


import SwiftUI
import SwiftData

@main
struct CharacterSheetApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            RPGCharacter.self,
            Stat.self,
            RulesLibrary.self,
            SkillTemplate.self,
            CharacterSkill.self,
            GoalRollTemplate.self,
            CharacterGoalRoll.self
        ])
    }
}