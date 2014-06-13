#  Brightbox - Manage the Cache directory
#  Copyright (c) 2012, Brightbox Systems
#  Author: Neil Wilson

class ImageCache

  attr_reader :cache_dir, :write_dir, :max_blocks

  def initialize(cache_root='/var/cache/domtrix', max_blocks=10485760)
    @cache_dir = File.join(cache_root, 'cache')
    @write_dir = File.join(cache_root, 'temp')
    @max_blocks = max_blocks.to_i
    FileUtils.mkdir_p(cache_dir, :mode => 02775)
    FileUtils.mkdir_p(write_dir, :mode => 02775)
  end

  def prune
    cum_blocks = 0
    sorted_cache_entries.each do |entry|
      cum_blocks += entry.blocks
      entry.zap if cum_blocks > max_blocks
    end
  end

  def clean
    FileUtils::rm_f all_cache_files
  end

  def sorted_cache_entries
    all_cache_files.collect {|fname| FileStatLru.new(fname)}.sort
  end

  def commit(source, id)
    FileUtils::mv(source, File.join(cache_dir, id))
  end

private
  
  def all_cache_files
    Dir[File.join(cache_dir, '*')]
  end

end
