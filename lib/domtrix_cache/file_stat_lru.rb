#  Brightbox - LRU Ordered File::Stat
#  Copyright (c) 2012, Brightbox Systems
#  Author: Neil Wilson

class FileStatLru < File::Stat

  def initialize(fname)
    @fname = fname
    super(fname)
  end

  attr_reader :fname

  def <=>(other)
    other.atime <=> self.atime
  end
  
  def inspect
    super.sub(/>$/, ", fname=#{@fname}>")
  end

  def zap
    File.unlink(fname)
  end

end
