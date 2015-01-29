class Canvas::GenericUrlProcessor

  def initialize(request_object, course)
    @thumbnail_generator = ThumbnailGenerator.new(request_object, course)
  end

  def call(submission)
    user_id        = submission['user_id']
    assignment_id  = submission['assignment_id']
    submitted_at   = submission['submitted_at']
    url            = submission['url']
    image_url      = submission.try(:[], 'attachments').try(:first).try(:[],'url')

    # Generate a thumbnail for the URL. Because the image URL is generated by canvas asynchronously, the
    # image_url might not immediately be available. Obviously we can only generate a thumbnail once the
    # image_url is present
    thumbnail_url = nil
    if image_url
      thumbnail_url = @thumbnail_generator.generate_and_upload(assignment_id, image_url, 'image/jpeg', {quality: 100, gravity: 'north'})
    end

    # If this is a new submission, or the previous submission was of a different type, the previous_item
    # will be nil. We can delete all other types (files and media urls) and create a new generic url
    previous_item = GenericUrl.where({assignment_id: assignment_id, canvas_user_id: user_id}).first
    if previous_item.nil?
      # Delete media urls and file uploads (attachments)
      MediaUrl.where({canvas_assignment_id: assignment_id, canvas_user_id: user_id}).delete_all
      Attachment.where({assignment_id: assignment_id, canvas_user_id: user_id}).delete_all

      # Create a new generic url
      GenericUrl.create({
        assignment_id: assignment_id,
        canvas_user_id: user_id,
        url: url,
        image_url: image_url,
        thumbnail_url: thumbnail_url,
        submitted_at: submitted_at
      })

    # Otherwise this is either:
    #  - a resubmission of a generic URL with an updated generic URL
    #  - a submission of a generic URL for which canvas finally generated an image
    # We can simply update the old record.
    # TODO: Should we delete rather than update as things like likes might no longer be relevant?
    else
      # Update the metadata in the database
      previous_item.update_attributes({
        url: url,
        image_url: image_url,
        thumbnail_url: thumbnail_url,
        submitted_at: submitted_at
      })
    end

  end

end
