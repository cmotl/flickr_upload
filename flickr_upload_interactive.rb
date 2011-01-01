#!/usr/bin/env ruby

require 'FlickRaw'
require 'logger'
require './flickr_config' #API_KEY, SHARED_SECRET, TOKEN

FlickRaw.api_key=API_KEY
FlickRaw.shared_secret=SHARED_SECRET

auth = flickr.auth.checkToken :auth_token => TOKEN

def sort_photosets_by_date()
  photosets = flickr.photosets.getList
  photosets = photosets.sort_by { |item| item.title }
  photosets.reverse!
  
  photoset_ids = Array.new
  
  photosets.each { |photoset|
    photoset_ids << photoset.id
  }
  
  photoset_ids_string = photoset_ids.join ','
  
  flickr.photosets.orderSets :photoset_ids => photoset_ids_string
end

##
##def create_collection_for_year(year)
##  photosets = flickr.photosets.getList
##  photosets_year = Array.new
##  photosets.each { |photoset|
##    if photoset.title.match(/^#{year}/)
##      photosets_year << photoset
##    end
##  }
##  
##  photosets_year = photosets_year.sort_by {|photoset| photoset.title}
##  photosets_year.reverse!
##  
##  flickr.collections.
##end
##

def number_of_photosets_for_year(year)
  photosets = flickr.photosets.getList
  photosets_year = Array.new
  photosets.each { |photoset|
    if photoset.title.match(/^#{year}/)
      photosets_year << photoset
    end
  }
  
  photosets_year.length
end