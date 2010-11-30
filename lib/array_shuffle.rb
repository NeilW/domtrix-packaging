#!/usr/bin/env ruby
#    Brightbox - Patch up 1.8.6 Array so Stomp will work
#    Copyright (C) 2010, Neil Wilson, Brightbox Systems
#
#  Add shuffle commands to Array if not already defined

unless [].respond_to? :shuffle!
  class Array
    # Shuffle the array
    def shuffle!
      n = length
      for i in 0...n
	r = Kernel.rand(n-i)+i
	self[r], self[i] = self[i], self[r]
      end
      self
    end

    # Return a shuffled copy of the array
    def shuffle
      dup.shuffle!
    end
  end
end

