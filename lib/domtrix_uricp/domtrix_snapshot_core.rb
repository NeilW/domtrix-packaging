class DomtrixSnapshotCore < DomtrixUriBase

  include CommandRunner

  def obtain_local_file
    raise error_class, "Snapshot for #{url_path} already exists" if exist?
    snapshot_file = create_snapshot
    begin
      yield snapshot_file
    rescue => e
      raise error_class, e.message
    ensure
      remove_snapshot snapshot_file
    end
  end

end
