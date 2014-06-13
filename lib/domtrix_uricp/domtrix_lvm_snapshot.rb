class DomtrixLvmSnapshot < DomtrixSnapshotCore

  def create_snapshot
    run(
      "lvcreate --snapshot --size #{snapshot_size}k --name #{snapshot_name} -c 512 #{url_path}",
      "create snapshot #{snapshot_name} from #{url_path}",
      "Failed to create snapshot of #{url_path}"
    )
    snapshot_path
  rescue => e
    raise error_class, e.message
  end

  def remove_snapshot(snapshot_file)
    run(
      "lvremove -f #{snapshot_file}",
      "remove LVM snapshot - #{snapshot_file}",
      "Failed to remove LVM snapshot - #{snapshot_file}"
      )
  rescue => e
    raise error_class, e.message
  end

  def exist?
    File.symlink? snapshot_path
  end

  def snapshot_name
    @snapshot_name ||= basename + "_frozen"
  end

  def snapshot_path
    @snapshot_path ||= url_path + "_frozen"
  end

private

  def reduction_factor
    6 * 1024
  end

  def snapshot_size
    @snapshot_size ||= cmd("lvs --units b -o lv_size --noheadings #{url_path}").to_i.div(reduction_factor)
  end

end
