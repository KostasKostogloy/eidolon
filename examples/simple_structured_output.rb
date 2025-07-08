require 'eidolon'

# Simple example using the schema_property method
class Recipe
  include Eidolon::StructuredOutput
  
  schema_property :name, description: "Name of the recipe", required: true
  schema_property :prep_time, description: "Preparation time in minutes", required: true, type: "integer"
  schema_property :ingredients, description: "List of ingredients", required: true, type: "array"
  schema_property :instructions, description: "Cooking instructions", required: true, type: "array"
  schema_property :difficulty, description: "Difficulty level", required: true, enum_values: ["easy", "medium", "hard"]
end

# Agent that extracts recipes
class RecipeAgent < Eidolon::Agent
  def provider
    # You can use any provider for structured output
    Eidolon::Providers::OpenAI.new(
      api_key: ENV['OPENAI_API_KEY'],
      model: 'gpt-4o'
    )
  end

  def instructions
    "You are a culinary expert who extracts recipe information from text descriptions."
  end
end

# Usage:
# agent = RecipeAgent.new
# 
# recipe_text = "I love making chocolate chip cookies! They take about 15 minutes to prep. You need flour, sugar, eggs, butter, chocolate chips, and vanilla. First mix the dry ingredients, then cream butter and sugar, add eggs and vanilla, combine everything, fold in chocolate chips, and bake for 12 minutes at 350°F. It's pretty easy to make!"
# 
# recipe = agent.structured(recipe_text, Recipe)
# 
# puts "Recipe: #{recipe.name}"
# puts "Prep Time: #{recipe.prep_time} minutes"
# puts "Difficulty: #{recipe.difficulty}"
# puts "Ingredients:"
# recipe.ingredients.each { |ingredient| puts "  - #{ingredient}" }
# puts "Instructions:"
# recipe.instructions.each_with_index { |step, i| puts "  #{i+1}. #{step}" }