require 'aws-sdk'

# Create a two-digit, zero-padded string from n
def zerofill2(n)
  n.to_s.rjust(2, "0")
end

# Returns Snapshot object
def start_snapshot(rds_instance)
    date = Time.new
    date_time = date.year.to_s + '-' \
        + zerofill2(date.month) + '-' + zerofill2(date.day) + '-' \
        + zerofill2(date.hour) + '-' + zerofill2(date.min)
    snapshot = rds_instance.create_snapshot(
        db_snapshot_identifier: rds_instance.db_instance_identifier + '-' + date_time
    # we can add tags to the snap when it is created
    # ,
    # tags: [
    #   { key: "myisam-snap-process", value: "creating" }
    # ]
    )

    puts "Created snapshot #{snapshot.snapshot_id}."

    snapshot
end

# Return list of pending snapshots
def pending_snapshots(rds_instance)
    snaps = rds_instance.snapshots(snapshot_type: 'manual')

    pendingSnaps = snaps.select do |snap|
        # puts "snapshot: #{snap.snapshot_id} #{snap.status}"
        snap.status == 'creating'
    end

    puts "#{pendingSnaps.size} pending snapshots." if !pendingSnaps.empty?
    puts 'No pending snapshots.' if pendingSnaps.empty?

    pendingSnaps
end

def wait_for_snapshot(snapshot, max_attempts = 72)
    snap_available = snapshot.wait_until(max_attempts: max_attempts, delay: 5) do |snap|
        puts "Snapshot progress: #{snap.percent_progress}% - #{snap.status}"

        # less conservative test
        # snap.percent_progress == 100

        # more conservative test
        snap.status == 'available'
    end
    if (snap_available) then
      return snapshot.reload
    else
      return nil
    end
end

def create_snapshot(instance_name)
    # rds = Aws::RDS::Resource.new(region: 'us-east-1', profile: 'commercial')
    rds = Aws::RDS::Resource.new

    instance = rds.db_instance(instance_name)

    pendingSnaps = pending_snapshots(instance)
    return nil unless pendingSnaps.empty?

    snap = start_snapshot(instance)

    completed_snap = wait_for_snapshot(snap)
    puts 'Snapshot is complete.' unless completed_snap.nil?
    puts 'Problem creating snapshot.' if completed_snap.nil?

    completed_snap
end

# snapshot.client.add_tags_to_resource({
#   resource_name: "arn:aws:rds:us-east-1:519591282851:snapshot:#{snapshot.snapshot_id}",
#   tags: [
#     { key: "myisam-snap-process", value: "complete" }
#   ]
# })
#
# resp = snapshot.client.list_tags_for_resource({
#   resource_name: "arn:aws:rds:us-east-1:519591282851:snapshot:#{snapshot.snapshot_id}"})
#
