class DomtrixQcowSnapshot < DomtrixSnapshotCore

  include DomtrixQemuTools
  include DomtrixQcowVolumeNames

  def server
    @server ||= (basename =~ /(srv-\w{5})-vol/ && Regexp.last_match[1])
  end

  def server_running?
    server && run(server_running_command)
  end

  def exist?
    File.exist?(url_path) && File.exist?(alt_url_path)
  end

  def create_snapshot
    if server_running?
      create_running_snapshot
    else
      create_offline_snapshot
    end
  end

  def remove_snapshot(snap_file)
    if server_running?
      merge_down snap_file
    else
      rebase_excluding snap_file
    end
  end

  def create_offline_snapshot
    File.rename(url_path, alt_url_path) if File.exist?(url_path)
    Syslog.info("#{self.class.name}: Creating offline snapshot")
    to = alternate_path
    from = current_path
    raise "Can't determine current and alternate path" unless to && from
    qemu_create(from, to)
    from
  rescue => e
    qemu_shred(to) if File.exists?(to.to_s)
    ensure_on_url_path
    raise error_class, e.message
  end

  def create_running_snapshot
    Syslog.info("#{self.class.name}: Creating running snapshot")
    to = alternate_path
    from = current_path
    raise "Can't determine current and alternate path" unless to && from
    virsh_create_snapshot(from, to)
    from
  rescue => e
    qemu_shred(to) if File.exists?(to.to_s)
    raise error_class, e.message
  end

  def rebase_excluding(snapshot)
    Syslog.info("#{self.class.name}: Merging snapshot offline")
    qemu_rebase(snap_file, run_file(snapshot))
    qemu_shred(snapshot) if File.exist?(snapshot)
    ensure_on_url_path
  rescue => e
    raise error_class, e.message
  end

  def merge_down(snapshot)
    Syslog.info("#{self.class.name}: Merging snapshot online")
    virsh_blockcommit(run_file(snapshot), snapshot, snap_file)
    qemu_shred(snapshot)if File.exist?(snapshot)
  rescue => e
    raise error_class, e.message
  end

private

  def run_file(snapshot)
    snapshot == alt_url_path ? url_path : alt_url_path
  end

  def ensure_on_url_path
    File.rename(alt_url_path, url_path) if url_path && alt_url_path && File.exist?(alt_url_path) && !File.exist?(url_path)
  end
  
  def server_running_command
    "virsh domstate #{server} > /dev/null 2>&1"
  end

  def virsh_blockcommit(current, top, base)
    run(
      "virsh blockcommit --domain #{server} #{current} --base #{base} --top #{top} --wait",
      "commit #{top} into #{base}",
      "Block Commit Failure into #{base}"
    )
  end

  def virsh_create_snapshot(from, to)
    run(
      "virsh snapshot-create-as #{server} #{server}-snap --diskspec #{from},file=#{to} --disk-only --atomic --no-metadata",
      "switch running file of #{server} to #{to}",
      "Failed to switch running file of #{server} to #{to}"
    )
  end

end
