#!/usr/bin/env ruby

require 'FlickRaw'
require 'logger'
require 'flickr_config' #API_KEY, SHARED_SECRET, TOKEN

#flush output to stdout immediately
STDOUT.sync = true

$log = Logger.new "flickr_upload.log"

def show_usage()
  puts
  puts "Usage: flickr_upload.rb path"
  puts "  path - File or directory to upload to flickr"
  puts "       - A single file will be added to the photostream"
  puts "       - A directory will create a new set and places all photos in that set."
  puts
end


def upload_file(file)
  puts      "  Uploading file: #{file} "
  $log.info "  Uploading file: #{file} "
  #photo_id = 1
  
  failed = true
  
  while failed == true
    
    begin
      photo_id = flickr.upload_photo file
    #rescue FlickRaw::FailedResponse => e
    rescue Exception => e
      puts      "    *** file upload failed : #{e.msg} ***"
      $log.info "    *** file upload failed : #{e.msg} ***"

      sleep 10

      puts      "  Reattempting upload of file: #{file}"
      $log.info "  Reattempting upload of file: #{file}"
      next
    rescue Timeout::Error => e
      puts      "    *** file upload failed : #{e.msg} ***"
      $log.info "    *** file upload failed : #{e.msg} ***"

      sleep 10

      puts      "  Reattempting upload of file: #{file}"
      $log.info "  Reattempting upload of file: #{file}"
      next
    end
    
    failed = false
  end
  
  puts      "  Setting permissions for #{photo_id}"
  $log.info "  Setting permissions for #{photo_id}"
  
  failed = true
  while failed == true
    begin
      flickr.photos.setPerms :photo_id => photo_id, :is_public => 0, :is_friend => 0, :is_family => 0, :perm_comment => 3, :perm_addmeta => 3
    rescue Exception => e
      puts      "    *** setting permissions failed : #{e.msg} ***"
      $log.info "    *** setting permissions failed : #{e.msg} ***"

      sleep 10

      puts      "  Reattempting setting permissions for file: #{file}"
      $log.info "  Reattempting setting permissions for file: #{file}"
      next
    rescue Timeout::Error => e
      puts      "    *** setting permissions failed : #{e.msg} ***"
      $log.info "    *** setting permissions failed : #{e.msg} ***"

      sleep 10

      puts      "  Reattempting setting permissions for file: #{file}"
      $log.info "  Reattempting setting permissions for file: #{file}"
      next
    end
    
    failed = false
  end
  
  
  puts      "    Completed with id #{photo_id}"
  $log.info "    Completed with id #{photo_id}"
  
  return photo_id
end

def create_set(set_name, primary_photo_id)
  puts      "  Creating set: #{set_name}"
  $log.info "  Creating set: #{set_name}"

  failed = true
  
  while failed == true  
    begin
      photoset = flickr.photosets.create :title => set_name, :primary_photo_id => primary_photo_id
    rescue Exception => e
      puts      "    *** creating set failed : #{e.msg} ***"
      $log.info "    *** creating set failed : #{e.msg} ***"

      sleep 10

      puts      "  Reattempting creating set: #{set_name}"
      $log.info "  Reattempting creating set: #{set_name}"
      next
    rescue Timeout::Error => e
      puts      "    *** creating set failed : #{e.msg} ***"
      $log.info "    *** creating set failed : #{e.msg} ***"

      sleep 10

      puts      "  Reattempting creating set: #{set_name}"
      $log.info "  Reattempting creating set: #{set_name}"
      next
    end
  
    failed = false
  end

  puts      "    Completed with id #{photoset.id}"
  $log.info "    Completed with id #{photoset.id}"
  return photoset.id
  #return 2
end

def upload_folder(folder_name)
  
  photo_ids = Array.new
  folders = Array.new
  
  Dir.chdir(folder_name)
  
  puts      "Uploading folder: #{folder_name}"
  $log.info "Uploading folder: #{folder_name}"
  
  puts      "Current location: " << Dir.pwd
  $log.info "Current location: " << Dir.pwd
  
  files = Dir.glob("*")
  
  files.each do |file|
    if FileTest.directory?(file)
      folders << file
    else
      if /jpg|jpeg|gif|png/i =~ File.extname(file)#is it an image?
        photo_id = upload_file file
        photo_ids << photo_id
      else
        puts      "  #{file} is not of allowed type to upload"
        $log.info "  #{file} is not of allowed type to upload"
      end
    end
  end
  
  if photo_ids.length > 0
    photosets_list = flickr.photosets.getList
    photoset_to_upload_to = nil
    
    photosets_list.each { |item|
    
      if(item.title == folder_name)
        photoset_to_upload_to = item
        break
      end
      
    }
    
    if(photoset_to_upload_to == nil)
      photoset_id = create_set folder_name, photo_ids[0]
  
      photo_ids.delete_at 0
    else
      photoset_id = photoset_to_upload_to.id
    end
    
  
    photo_ids.each do |photo_id|
      add_photo_to_set photo_id, photoset_id
    end
  end
  
  puts
    
  folders.each do |folder|
    upload_folder folder
  end
  
  Dir.chdir("..")

end

def add_photo_to_set(photo_id, photoset_id) 
  puts      "  Adding photo #{photo_id} to set #{photoset_id}"
  $log.info "  Adding photo #{photo_id} to set #{photoset_id}"
  failed = true
  while failed == true  
    begin
      flickr.photosets.addPhoto :photoset_id => photoset_id, :photo_id => photo_id
    rescue Exception => e
      puts      "    *** adding photo to set failed : #{e.msg} ***"
      $log.info "    *** adding photo to set failed : #{e.msg} ***"

      sleep 10

      puts      "  Reattempting to add photo: #{photo_id} to set #{photoset_id}"
      $log.info "  Reattempting to add photo: #{photo_id} to set #{photoset_id}"
      next
    rescue Timeout::Error => e
      puts      "    *** adding photo to set failed : #{e.msg} ***"
      $log.info "    *** adding photo to set failed : #{e.msg} ***"

      sleep 10

      puts      "  Reattempting to add photo: #{photo_id} to set #{photoset_id}"
      $log.info "  Reattempting to add photo: #{photo_id} to set #{photoset_id}"
      next
    end
    
    failed = false
  end
  
end

if ARGV.length != 1 
  show_usage 
end

path = ARGV[0];

puts      "Initializing flickr upload"
$log.info "Initializing flickr upload"

FlickRaw.api_key=API_KEY
FlickRaw.shared_secret=SHARED_SECRET

auth = flickr.auth.checkToken :auth_token => TOKEN

puts      "Starting upload for #{path}"
$log.info "Starting upload for #{path}"

upload_folder path

puts      "Completed upload to flickr"
$log.info "Completed upload to flickr"