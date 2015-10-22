require "monitor"

Thread.abort_on_exception = true   # to avoid hiding errors in threads 

#------------------------------------
# Global Variables
        
$headerPorts = "=== Starports ==="
$headerShips = "=== Starships ==="
$headerTraveler = "=== Travelers ==="
$headerOutput = "=== Output ==="

$simOut = []            # simulation output

$starport = []
$starship = []
$traveler = []
$traveler_done = []

$printMonitor = Monitor.new

#----------------------------------------------------------------
# Starport 
#----------------------------------------------------------------

class Starport
    attr_accessor :name
    attr_accessor :size
    attr_accessor :ships
    attr_accessor :travelers
    attr_accessor :monitor
    attr_accessor :con_traveler
    attr_accessor :con_ship

    def initialize (name,size)
        @name = name
        @size = size
        @ships = []
        @travelers = []
        @monitor = Monitor.new
        @con_traveler = @monitor.new_cond()
        @con_ship = @monitor.new_cond()
    end
    
    def to_s
        @name
    end

    def size
        @size
    end
    
    def arrive(person)
        @travelers.push(person)
    end

    def goPass(traveler)
        if traveler.ship == nil && traveler.itinerary.size > 1 then
            board_ship(traveler)
            traveler.itinerary.delete_at(0)
        elsif traveler.ship != nil && traveler.itinerary.size > 0 then
            traveler.itinerary[0].depart_ship(traveler)
        else
            traveler.status = "done"
        end
    end

    def goShip(ship)
        if ship.port == ship.next_port
            ship.port.dock(ship)
        else
            takeoff(ship)
        end
    end

    def board_ship(traveler)
        @monitor.synchronize do
            @con_traveler.wait_until {@ships.size > 0 && @ships[0].size > @ships[0].passengers.size}
            traveler.ship = ships[0]
            traveler.ship.passengers.push(traveler)
            @travelers.delete(traveler)
            $printMonitor.synchronize do
                puts "#{traveler} boarding #{traveler.ship} at #{self}"
                $stdout.flush
            end
            traveler.port = traveler.next_port
        end
    end

    def depart_ship(traveler)
        monitor.synchronize do
            @con_traveler.wait_until {traveler.itinerary[0].ships.include?(traveler.ship) == true}
            traveler.ship.passengers.delete(traveler)
            @travelers.push(traveler)
            $printMonitor.synchronize do
                puts "#{traveler} departing #{traveler.ship} at #{self}"
                $stdout.flush
            end
            traveler.ship = nil
            sleep 0.001
        end
    end

    def dock(ship)
        @monitor.synchronize do
            @con_ship.wait_until {self.size > self.ships.size && self == ship.port}
            self.ships.push(ship)
            $printMonitor.synchronize do
                puts "#{ship} docking at #{self}"
                $stdout.flush
            end
            ship.next_port = next_port(ship.port)
            @con_traveler.broadcast()
        end
        sleep 0.001
    end

    def takeoff(ship)
        @monitor.synchronize do
            self.ships.delete(ship)
            $printMonitor.synchronize do
                puts "#{ship} departing from #{self}"
                $stdout.flush
            end
            ship.port = ship.next_port
            @con_ship.broadcast()
        end
    end
end

#------------------------------------------------------------------
# find_name(name) - find port based on name

def find_name(arr, name)
    arr.each { |p| return p if (p.to_s == name) }
    puts "Error: find_name cannot find #{name}"
        $stdout.flush
end

#------------------------------------------------------------------
# next_port(c) - find port after current port, wrapping around

def next_port(current_port)
    port_idx = $starport.index(current_port)
    if !port_idx
        puts "Error: next_port missing #{current_port}"
        $stdout.flush
        return  $starport.first
    end
    port_idx += 1
    port_idx = 0 if (port_idx >= $starport.length)
    $starport[port_idx]
end

#----------------------------------------------------------------
# Starship 
#----------------------------------------------------------------

class Starship 
    attr_accessor :name
    attr_accessor :size
    attr_accessor :passengers
    attr_accessor :port
    attr_accessor :next_port

    def initialize (name,size)
        @name = name
        @size = size
        @passengers = []
        @port = nil
        @next_port = $starport[0]
    end
    
    def size
        @size
    end
        
    def to_s
        @name
    end
end         


#----------------------------------------------------------------
# Traveler 
#----------------------------------------------------------------

class Traveler
    attr_accessor :name
    attr_accessor :itinerary
    attr_accessor :next_stop_index
    attr_accessor :status
    attr_accessor :ship
    attr_accessor :done
    attr_accessor :next_port
    attr_accessor :port
    attr_accessor :last_port


    def initialize(name, itinerary)
        @name = name
        @itinerary = itinerary
        @next_stop_index = 0
        @status = "at port"
        @ship = nil
        @done = false
        @next_port = @itinerary[0]
        @port = nil
        @last_port = @itinerary[-1]
    end

    def to_s
        @name
    end
    
    def itinerary
        @itinerary
    end
end

#------------------------------------------------------------------
# read command line and decide on display(), verify() or simulate()

def readParams(fname)
    begin
        f = File.open(fname)
    rescue Exception => e
        puts e
        $stdout.flush
        exit(1)
    end

    section = nil
    f.each_line{|line|

        line.chomp!
        line.strip!
        if line == "" || line =~ /^%/
            # skip blank lines & lines beginning with %

        elsif line == $headerPorts || line == $headerShips ||
        line == $headerTraveler || line == $headerOutput
            section = line

        elsif section == $headerPorts
            parts = line.split(' ')
            name = parts[0]
            size = parts[1].to_i
            $starport.push(Starport.new(name,size))
                
        elsif section == $headerShips
            parts = line.split(' ')
            name = parts[0]
            size = parts[1].to_i
            $starship.push(Starship.new(name,size))

        elsif section == $headerTraveler
            parts = line.split(' ')
            name = parts.shift
            itinerary = []
            parts.each { |p| itinerary.push(find_name($starport,p)) }
            person = Traveler.new(name,itinerary)
            $traveler.push(person)
            find_name($starport,parts.first).arrive(person)

        elsif section == $headerOutput
            $simOut.push(line)

        else
            puts "ERROR: simFile format error at #{line}"
            $stdout.flush
            exit(1)
        end
    }
end

#------------------------------------------------------------------
# 

def printParams()
    
    puts $headerPorts
    $starport.each { |s| puts "#{s} #{s.size}" }
    
    puts $headerShips 
    $starship.each { |s| puts "#{s} #{s.size}" }
    
    puts $headerTraveler 
    $traveler.each { |p| print "#{p} "
                               p.itinerary.each { |s| print "#{s} " } 
                               puts }

    puts $headerOutput
    $stdout.flush
end

#----------------------------------------------------------------
# Simulation Display
#----------------------------------------------------------------

def array_to_s(arr)
    out = []
    arr.each { |p| out.push(p.to_s) }
    out.sort!
    str = ""
    out.each { |p| str = str << p << " " }
    str
end

def pad_s_to_n(s, n)
    str = "" << s
    (n - str.length).times { str = str << " " }
    str
end

def ship_to_s(ship)
    str = pad_s_to_n(ship.to_s,12) << " " << array_to_s(ship.passengers)
    str
end

def display_state()
    puts "----------------------------------------"
    $starport.each { |port|
        puts "#{pad_s_to_n(port.to_s,13)} #{array_to_s(port.travelers)}"
        out = []
        port.ships.each { |ship| out.push("  " + (ship_to_s(ship))) }
        out.sort.each { |line| puts line }
    }
    puts "----------------------------------------"
end


#------------------------------------------------------------------
# display - print state of space simulation

def display()
    display_state()
    $simOut.each {|o|
        puts o
        if o =~ /(\w+) (docking at|departing from) (\w+)/
            ship = find_name($starship,$1); 
            action = $2;
            port = find_name($starport,$3); 
            if (action == "docking at")
                port.ships.push(ship)
            else
                port.ships.delete(ship)
            end
                
        elsif o =~ /(\w+) (board|depart)ing (\w+) at (\w+)/
            person = find_name($traveler,$1); 
            action = $2;
            ship = find_name($starship,$3); 
            port = find_name($starport,$4); 
            if (action == "board")
                ship.passengers.push(person)
                port.travelers.delete(person)
            else 
                ship.passengers.delete(person)
                port.travelers.push(person)
            end
        else
            puts "% ERROR Illegal output #{o}"
        end
        display_state()
    }
end


#------------------------------------------------------------------
# verify - check legality of simulation output

def verify
    validSim = true
    $simOut.each {|o|

        if o =~ /(\w+) (docking at|departing from) (\w+)/
            ship = find_name($starship,$1); 
            action = $2;
            port = find_name($starport,$3);
            if ship.port = nil
                ship.port = $starport[0]
            else
                ship.port = ship.next_port
            end

            if (action == "docking at")
                # check if travelling in correct order
                if port == ship.port then
                    # check if does not exceed port capacity
                    if port.size > port.ships.size then
                        port.ships.push(ship)
                    else
                        puts "% ERROR Illegal output #{o}"
                        validSim = false
                    end
                else
                    puts "% ERROR Illegal output #{o}"
                    validSim = false
                end

            
            elsif action == "departing from" then
                # check if starport is at port before leaving
                if port.ships.include?(ship) == true then
                    port.ships.delete(ship)
                    ship.next_port = next_port(ship.port)
                else
                    puts "% ERROR Illegal output #{o}"
                    validSim = false
                end
            end
                
        elsif o =~ /(\w+) (board|depart)ing (\w+) at (\w+)/
            person = find_name($traveler,$1); 
            action = $2;
            ship = find_name($starship,$3); 
            port = find_name($starport,$4); 

            if (action == "board")
                if person.itinerary[0] == port then
                    person.itinerary.delete_at(0)
                    if port.ships.include?(ship) == true then
                        if ship.size > ship.passengers.size then
                            ship.passengers.push(person)
                            port.travelers.delete(person)
                        else
                            puts "% ERROR Illegal output #{o}"
                            validSim = false
                        end
                    else
                        puts "% ERROR Illegal output #{o}"
                        validSim = false
                    end
                else
                    puts "% ERROR Illegal output #{o}"
                    validSim = false
                end

            elsif action == "depart" then
                if person.itinerary[0] == port then
                    if port.ships.include?(ship) == true then
                        ship.passengers.delete(person)
                        port.travelers.push(person)
                        person.port = port
                    else
                        puts "% ERROR Illegal output #{o}"
                        validSim = false
                    end
                else
                    puts "% ERROR Illegal output #{o}"
                    validSim = false
                end
                if person.itinerary.size == 1 && person.itinerary[0] != person.last_port then
                    puts "fail"
                    validsim = false
                end
            end 
        else
            puts "% ERROR Illegal output #{o}"
            validSim = false
        end
    }
    $starship.each do |x|
        if x.passengers.size != 0 then
            validSim = false
        end
    end
    return validSim
end

#------------------------------------------------------------------
# simulate - perform multithreaded space simulation

def passengerSim(passenger)
    while passenger.status != "done" do
        passenger.itinerary[0].goPass(passenger)
    end
    $traveler_done[$traveler.find_index(passenger)] = true
end

def starshipSim(ship)
    ship.port = ship.next_port
    while $traveler_done.include?(false) == true do
        ship.port.goShip(ship)
    end
end

def simulate()
    passengerThreads = Array.new
    starshipThreads = Array.new
    i = 0

    while i < $traveler.size
        $traveler_done[i] = false
        i += 1
    end

    $starship.each do |x|
        starshipThreads.push(
            Thread.new do
                starshipSim(x)
            end
        )
    end

    $traveler.each do |x|
        passengerThreads.push(
            Thread.new do
                passengerSim(x)
            end
        )   
    end

    passengerThreads.each do |x|
        x.join()
    end
end

#------------------------------------------------------------------
# main - simulation driver

def main
    if ARGV.length != 2
        puts "Usage: ruby space.rb [simulate|verify|display] <simFileName>"
        exit(1)
    end
    
    # list command line parameters
    cmd = "% ruby space.rb "
    ARGV.each { |a| cmd << a << " " }
    puts cmd
    
    readParams(ARGV[1])
  
    if ARGV[0] == "verify"
        result = verify()
        if result
            puts "VALID"
        else
            puts "INVALID"
            exit(1)
        end

    elsif ARGV[0] == "simulate"
        printParams()
        simulate()

    elsif ARGV[0] == "display"
        display()

    else
        puts "Usage: space [simulate|verify|display] <simFileName>"
        exit(1)
    end
    exit(0)
end

main
