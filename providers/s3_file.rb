include Opscode::Aws::S3

use_inline_resources

def whyrun_supported?
  true
end

action :create do
  do_s3_file(:create)
end

action :create_if_missing do
  do_s3_file(:create_if_missing)
end

action :delete do
  do_s3_file(:delete)
end

action :touch do
  do_s3_file(:touch)
end

def do_s3_file(resource_action)
  remote_path = new_resource.remote_path
  remote_path.sub!(%r{^/*}, '')
  skip_action = false

  obj = ::Aws::S3::Object.new(bucket_name: new_resource.bucket, key: remote_path, client: s3)
  s3url = obj.presigned_url(:get, expires_in: 300)

  if resource_action == :create
    if Opscode::Aws::S3.compare_md5s(obj, new_resource.path)
      Chef::Log.info("Remote and local files appear to be identical, skipping #{resource_action} operation.")
      skip_action == true
    end
  end

  unless skip_action
    remote_file new_resource.name do
      path new_resource.path
      source s3url.gsub(%r{https://([\w\.\-]*)\.\{1\}s3.amazonaws.com:443}, 'https://s3.amazonaws.com:443/\1') # Fix for ssl cert issue
      owner new_resource.owner
      group new_resource.group
      mode new_resource.mode
      checksum new_resource.checksum
      backup new_resource.backup
      headers new_resource.headers
      use_etag new_resource.use_etag
      use_last_modified new_resource.use_last_modified
      atomic_update new_resource.atomic_update
      force_unlink new_resource.force_unlink
      manage_symlink_source new_resource.manage_symlink_source
      if node['platform_family'] == 'windows'
        inherits new_resource.inherits
        rights new_resource.rights
      end
      action resource_action
    end
  end
end
