require 'face'

Magickly.dragonfly.configure do |c|
  c.log_commands = true
  
  c.analyser.add :face_data do |temp_object|
    GooglyEyes.face_data(temp_object)
  end
  
  c.analyser.add :face_data_as_px do |temp_object|
    GooglyEyes.face_data_as_px(temp_object)
  end
  
  c.analyser.add :face_span do |temp_object|
    GooglyEyes.face_span(temp_object)
  end
  
  
  
  c.job :eyesify do |eye_num_param|
    photo_data = GooglyEyes.face_data_as_px(@job)
    width = photo_data['width']
    
    commands = ['-virtual-pixel transparent']
    photo_data['tags'].each do |face|
      eye_num = case eye_num_param
        when true
          0
        when 'true'
          0
        when 'rand'
          rand(GooglyEyes.eyes.size)
        else
          eye_num_param.to_i
      end
      
      eye = GooglyEyes.eyes[eye_num]
      
      # stick a googly eye over each of the real eyes
      # center coords of eyes: face['eye_left']['x'], face['eye_left']['y'], etc.

      # each eye is usually around 1/5 the width of the face
      # we'll use 1/4 of the face width for comically large eyes
      scale = (( width * ( face['width'] / 100 )) / 4) / eye['width']
      puts "face['height'] = #{face['height']}"
      puts "face['width'] = #{face['width']}"
      puts "eye['width'] = #{eye['width']}"
      puts "scale = #{scale}"
      
      # left eye
      rotation = rand(360)
      left_eye_srt_params = [
        [ eye['width'] / 2.0, eye['height'] / 2.0 ].map{|e| e.to_i }.join(','), # rotate around middle of googly eye image
        scale, # scale
        rotation, # random rotation
        [ face['eye_left']['x'], face['eye_left']['y'] ].map{|e| e.to_i }.join(',') # middle of eye
      ]
      left_eye_srt_params_str = left_eye_srt_params.join(' ')

      # right eye
      rotation = rand(360)
      right_eye_srt_params = [
        [ eye['width'] / 2.0, eye['height'] / 2.0 ].map{|e| e.to_i }.join(','), # rotate around middle of googly eye image
        scale, # scale
        rotation, # rotate
        [ face['eye_right']['x'], face['eye_right']['y'] ].map{|e| e.to_i }.join(',') # middle of eye
      ]
      right_eye_srt_params_str = right_eye_srt_params.join(' ')
      
      # right eye
      
      # commands << "\\( #{mustache['file_path']} +distort SRT '#{srt_params_str}' \\)"
      commands << "\\( #{eye['file_path']} +distort SRT '#{left_eye_srt_params_str}' \\)"
      commands << "\\( #{eye['file_path']} +distort SRT '#{right_eye_srt_params_str}' \\)"
    end
    commands << "-flatten"
    
    command_str = commands.join(' ')
    process :convert, command_str
  end
  
  c.job :crop_to_faces do |geometry|
    thumb_width, thumb_height = geometry.split('x')
    # raise ArgumentError
    thumb_width = thumb_width.to_f
    thumb_height = thumb_height.to_f
    
    span = GooglyEyes.face_span(@job)
    puts span.inspect
    scale_x = thumb_width / span[:width]
    scale_y = thumb_height / span[:height]
    
    # TODO
    # if thumb larger than span
    # center span and crop
    # else
    # resize image so span is smaller than thumb, then crop
    
    # center the span in the dimension with the smaller scale
    if scale_x < scale_y
      orig_height = @job.height
      # check if image is tall enough for this scaling
      if orig_height * scale_x >= thumb_height
        @scale = scale_x
        @offset_x = span[:left] * @scale
      else
        # image is too short - increase scale to fit height
        @scale = thumb_height / orig_height.to_f
        orig_width = @job.width
        @offset_x = span[:left] * @scale + ((@scale - scale_x) * orig_width / 2.0)
      end
      
      @offset_y = (span[:center_y] * @scale) - (thumb_height / 2)
    else
      orig_width = @job.width
      # check if image is wide enough for this scaling
      if orig_width * scale_y >= thumb_width
        @scale = scale_y
        @offset_y = span[:top] * @scale
      else
        # image is too narrow - increase scale to fit width
        @scale = thumb_width / orig_width.to_f
        orig_height = @job.height
        @offset_y = span[:top] * @scale + ((@scale - scale_y) * orig_height / 2.0)
      end
      
      @offset_x = (span[:center_x] * @scale) - (thumb_width / 2)
    end
    
    # round up, to ensure the scaled image fills the thumb area
    percentage = (@scale * 100).ceil
    
    process :convert, "-resize #{percentage}% -extent #{geometry}+#{@offset_x.to_i}+#{@offset_y.to_i}"
  end
end