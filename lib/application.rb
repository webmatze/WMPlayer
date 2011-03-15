require 'rubygems'
require 'hotcocoa'

class WMPlayer

  include HotCocoa
  
  def start
    @songs = []
    application :name => "WMPlayer" do |app|
      app.delegate = self
      window :size => [500, 500], :title => "WMPlayer", :center => true, :shows_resize_indicator => true, :has_shadow => true,
              :style => [:titled, :closable, :miniaturizable, :resizable], :view => :nolayout do |win|
        
        win.view = layout_view(:layout => {:expand => [:width, :height], :padding => 0, :margin => 0}) do |vert|
          
          #Player Buttons
          vert << layout_view(:size => [0, 40], :mode => :horizontal, :layout => {:padding => 0, :margin => 0, :expand => [:width]}) do |horizont|
            horizont << @play_button = button(:title => 'Play', :bezel => :thicker_square, :layout => {:align => :center}, :on_action => Proc.new {play_song})
            horizont << @stop_buton = button(:title => 'Stop', :bezel => :thicker_square, :layout => {:align => :center}, :on_action => Proc.new {stop_song})
            horizont << @progress_bar = progress_indicator(:layout => { :expand => [:width] })
          end
          
          #Liste der Songs aus dem Verzeichnsi
          vert << scroll_view(:layout => {:expand => [:width, :height]}) do |scroll|
            scroll.setAutohidesScrollers(true)
            scroll << @table = table_view(:columns => [
                  column(:id => :title, :title => 'Song Title', :editable => false),
                ], :data =>  self) do |table|
               table.setUsesAlternatingRowBackgroundColors(true)
               table.setGridStyleMask(NSTableViewSolidHorizontalGridLineMask) 
               table.setDoubleAction(:play_song) 
            end
          end
          
          #Verzeichnisauswahl
          vert << layout_view(:size => [0, 40], :mode => :horizontal, :layout => {:padding => 0, :margin => 0, :expand => [:width]}) do |horizont|
            horizont << @dir_button = button(:title => 'Verzeichnis wählen', :bezel => :recessed, :layout => {:align => :center, :expand => [:width]}, :on_action => Proc.new {load_dir})
          end
          
        end
        
        win.will_close { exit }
        
      end
    end

  end
  
  #NSTableView Delegate Methods
  
  def numberOfRowsInTableView(table)
    @songs.size
  end
  
  def tableView(table, objectValueForTableColumn:column, row:index)
    song = @songs[index]
    song[column.identifier]
  end
  
  #NSApp Delegate Methods
  
  def load_dir
    dialog = NSOpenPanel.openPanel
    dialog.canChooseFiles = false
    dialog.canChooseDirectories = true
    dialog.allowsMultipleSelection = false
    if dialog.runModalForDirectory(nil, file:nil) == NSOKButton
      @dir_button.title = dialog.filenames.first
      files = Dir.glob(@dir_button.title+"/**/*.{mp3,m4p,m4a}")
      @songs = Array.new
      files.each do |file|
        @songs << {:title => file.split("/").last, :file => file}
      end
      @table.reload
    end
    dialog = nil
  end
  
  def play_song
    stop_song
    if @table.selectedRow != -1 && @songs
      @sound = sound(:file => @songs[@table.selectedRow][:file])
      if @sound
        @sound.delegate = self
        @sound.play
        @progress_bar.indeterminate = false
        @progress_bar.maxValue = @sound.duration.to_f
        @progress_bar.show
        @progress_bar.start
        start_timer
      else
        alert(:message => "Fehler beim laden", :info => "Die Datei kann nicht abgespielt werden. Möglicherweise wird das Format nicht unterstüzt.")
      end
    end
  end
  
  def stop_song
    if @sound && @sound.isPlaying
      @sound.stop
      @sound = nil
      @timer.invalidate
      @timer =  nil
      @progress_bar.doubleValue = 0.0
    end
  end
  
  def start_timer
    @timer = NSTimer.scheduledTimerWithTimeInterval 0.5,
      target:self,
      selector:'update_progress_bar',
      userInfo:nil,
      repeats:true
  end
  
  def update_progress_bar
    @progress_bar.doubleValue = @sound.currentTime.to_f
  end
  
  def autoplay_next_song
    if @table.selectedRow < @table.numberOfRows-1
      @table.selectRowIndexes(NSIndexSet.indexSetWithIndex(@table.selectedRow+1), byExtendingSelection:false)
      play_song
    end
  end
    
  #NSSound Delegate Methods
  
  def sound(sound, didFinishPlaying:playbackSuccessful)
    @progress_bar.stop
    sound = nil
    if playbackSuccessful
      autoplay_next_song
    end
  end
    
end

WMPlayer.new.start