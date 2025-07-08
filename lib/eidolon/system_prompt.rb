module Eidolon
  class SystemPrompt
    attr_reader :background, :steps, :output_format
    
    def initialize(background: nil, steps: nil, output_format: nil)
      @background = Array(background)
      @steps = Array(steps)
      @output_format = output_format
    end
    
    def to_s
      parts = []
      
      unless @background.empty?
        parts << "Background:"
        parts += @background.map { |bg| "- #{bg}" }
        parts << ""
      end
      
      unless @steps.empty?
        parts << "Steps:"
        parts += @steps.each_with_index.map { |step, i| "#{i + 1}. #{step}" }
        parts << ""
      end
      
      if @output_format
        parts << "Output Format:"
        parts << @output_format
      end
      
      parts.join("\n").strip
    end
  end
end