# Multithreaded-Ruby

<body>

<h1 class="title">Multithreaded Space Simulation </h1>

<h2>Introduction</h2>

<p>
In this project, you will develop a multi-threaded Ruby program that
can be used to simulate space travel.  You will also write code 
to process simulation output to display the state of the simulation and
verify its feasibility. 

<h2>Project Description</h2>

<h3>Space Simulation Rules</h3>

We will begin by describing how the space simulation works.

In the simulation, there will be starships traveling between
starports, and passengers traveling between starports, each with
an itinerary.  There are a number of rules governing 
how starships and travelers may move between starports.

<ul>
<li> Starports
<p>
<ul>
<li> A list of starports (and its capacity in ships) is provided.
</ul>
<p>

<li> Starships
<p>
<ul>
<li>A list of starships (and its capacity in travelers) is provided.
<p>

<li>Starships are initially in space (not docked to a starport).
<p>

<li> Starships visit starports, in order from first to last in the list. 
When a starship visits the last starport in the list, it repeats the process
starting from the first starport on the list.
<p>

<li> The total number of starships docked at a starport must not exceed the
capacity of the starport. If there are multiple starships waiting to dock
with a starport, the order they dock is unspecified.
<p>

</ul>

<li> Travelers
<p>
<ul>
<li>A list of travelers (and their itinerary) is provided.
<p>

<li>  Each traveler's <i>itinerary</i> specifies which starport
they must visit, and in which order. Travelers ride starships
from port to port on their itinerary until they reach their final 
destination. 
<p>

<li> The same starport may occur on the itinerary multiple
times, but may not be adjacent to itself.
<p>

<li> At the start of the simulation, each traveler is at the first
starport on their itinerary.
<p>

<li>  Travelers wait at starports until a starship arrives, then
try to board the starship and ride it to the next starport on
the traveler's itinerary. Travelers may ride aboard any starship,
as long as the capacity of the starship is not exceeded. If multiple
travelers are trying to board a starship, the order they do so is 
unspecified.
<p>

<li> When a starship carrying a traveler arrives at the 
next station on the traveler's itinerary, the traveler
may attempt to disembark (depart the starship and enters 
the starport) while the starship is docked to the starport.
<p>

<li> It is possible that a traveler at a starport
may miss boarding a starship as it passes through.  In that case, 
the traveler remains at the starport and waits for an
opportunity to board another starship.
<p>

<li> Similarly, a traveler riding on a starship may miss 
the opportunity to leave the starship while it is in port.
In that case the traveler remains on the starship to
wait for another opportunity to disembark at the 
desired starport.
<p>

<li> Travelers continue moving from starport to starport until 
they reach the final starport on their itinerary.
<p>

<li> The simulation ends when all travelers reach the
final starport on their itinerary.
<p>

</ul>
</ul>

<h3>Space Simulation Outputs</h3>

A space simulation may be described by a number of simulation events, and
the order they occur.  Four simulation events and their associated 
messages are:

<ul>
<li> <i>starship</i> docking at <i>starport</i>
<li> <i>starship</i> departing from <i>starport</i>
<li> <i>traveler</i> boarding <i>starship</i> at <i>starport</i>
<li> <i>traveler</i> departing <i>starship</i> at <i>starport</i>
</ul>

The simulator must output these simulation messages in the order they occur.
These messages (and their order of occurrence) may then be analyzed 
and used to either display the state of the simulation, or to discover 
whether the simulation results are valid.
<p>
Because the simulation is multithreaded, the order messages 
are output is dependent on the thread scheduler. Running the
same simulation will likely produce different outputs each time.
<p>
The simulation output provided in the public tests is simply
an example of one possible output.  The output of your simulator
does not need to match it exactly.  In fact it will be unlikely
for your simulation output to be identical to the example
output provided, especially for large numbers of threads.
<p>


<h3>Space Simulation Parameters</h3>

Each space simulation is performed for a specific set of simulation parameters.
These parameters are stored in a <i>simulation file</i>, and include the 
following:

<ul>
<li> Starports - name of each starport and its capacity
<li> Starships - name of each starship and its capacity
<li> Travelers - name of each traveler followed by list of starports in itinerary
<li> Output - possible simulation output for simulation
</ul>

The following is an example simulation file:

<pre>
=== Starports ===
Earth 1
Vulcan 1
=== Starships ===
Enterprise 1
=== Travelers ===
Kirk Earth Vulcan 
=== Output ===
Enterprise docking at Earth
  Kirk boarding Enterprise at Earth
Enterprise departing from Earth
Enterprise docking at Vulcan
  Kirk departing Enterprise at Vulcan
</pre>

<h3>Space Simulation Driver</h3>

Code is provided in the initial space.rb file to read in
(and print out) the simulation parameters. Code is also
provided to examine the command line parameters
specifying the file containing simulation parameters,
and whether the program should 
perform a simulation or simply display or 
verify the feasibility of the simulation output.
The program may be invoked as:

<pre>
     ruby space.rb [simulate|display|verify] <i>simFileName</i>
</pre>

So typing <tt>ruby space.rb simulate public1.in</tt> would execute a
simulation using the simulation parameters in public1.in (ignoring 
any example simulation output in the file), while typing
<tt>ruby space.rb verify public1.in</tt> would perform
an analysis of the simulation output in public1.in to 
determine whether it is feasible.

<p>
The code in space.rb outputs simulation parameters before 
simulation output, so that its output (if saved in a file) may be 
passed directly to the simulation display/verify routines
for use in debugging your simulation.

<h2> Project Implementation </h2>

For this project, you are required to implement three major 
functions: display, verify, and simulate.  The three parts
may be implemented independently, though display and verify
are similar.

<h3>Part 1:  Simulation Display</h3>

A multithreaded simulation can clearly have many different behaviors,
depending on the thread scheduler.  One way to help determine whether
a simulation is proceeding correctly (i.e., avoiding data races) 
is to model the state of the simulation by processing the simulation 
outputs.  The model can then be used to display the state of the simulation,
and/or determine its validity.

<p>
The first part of your project is to implement a model of the 
simulation (by processing simulation event messages)
sufficiently detailed to display the following

<ul>
<li> Starships at each starport
<li> Travelers at each starport
<li> Travelers on board each starship
</ul>

Your code should display the initial state of the simulation.
Then it should list each simulation event messages in order, 
followed by a display of the state of the simulation after 
each event.
<p>
For instance, for the simulation parameters in public1.in 
described above, your code should display the initial
state of the simulation as follows:

<pre>
----------------------------------------
Earth         Kirk 
Vulcan        
----------------------------------------  
</pre>

Your code should then process the simulation event messages in the
simulation output, displaying the message and the resulting state.
For instance, after processing the message 
<tt>Enterprise docking at Earth</tt> in the simulation output, 
your model should contain enough information to
display the following:

<pre>
----------------------------------------
Enterprise docking at Earth
----------------------------------------
Earth         Kirk 
  Enterprise  
Vulcan        
----------------------------------------
Kirk boarding Enterprise at Earth
----------------------------------------
Earth         
  Enterprise  Kirk 
Vulcan        
----------------------------------------
Enterprise departing from Earth
----------------------------------------
Earth         
Vulcan        
----------------------------------------
Enterprise docking at Vulcan
----------------------------------------
Earth         
Vulcan        
  Enterprise  Kirk 
----------------------------------------
Kirk departing Enterprise at Vulcan
----------------------------------------
Earth         
Vulcan        Kirk 
  Enterprise  
----------------------------------------
</pre>

For the simulation display part of the project, you may assume the 
sample simulation output is valid.
<p>


<h3>Part 2:  Simulation Verifier</h3>

<p>
It should be clear that a multithreaded simulation may have 
many different behaviors, depending on the thread scheduler.  
However, there are certain restrictions on the simulation 
output, e.g., travelers can board starships only when those
starships are docked at the starport.
To help you debug your simulator, you will write a verifier
to examine your simulation outputs and
checks whether they are valid (i.e., follows all the
simulation rules in the project description). 
<p>
The list of possible errors in the simulation output is huge,
so you only need to check some common errors
associated with data races resulting from incorrect synchronization.
Many of these errors manifest as missing or out-of-order 
simulation messages. Some conditions you need to check are:
<p>

<ul>
<li>Starships are traveling between starports in the correct order
<li>Starships always dock at a starport before leaving it
<li>Starships do not exceed the capacity of a starport
<li>Travelers follow their itinerary
<li>Travelers only board or leave a starship while it is at a starport
<li>Travelers do not exceed the capacity of a starship
<li>All travelers have reached their final destination when simulation ends
</ul>
<p>

Your verifier should output either "VALID" or "INVALID", depending
on whether any illegal output is found.
<p>

<h3>Part 3:  Space Simulation</h3>

Finally, you will write a Ruby program
to performs a multithreaded simulation using the simulation
parameters supplied
(possibly reusing your code and data structures from part 1).
Your simulation should be implemented as follows.

<ul>
<li>Each starship and traveler in the simulation must be represented by its 
own thread.  Thus, if you are simulating m starships and n travelers, you should
be creating m+n threads.
<p>

<li>The initial state of the simulation should be as described in
the space simulation rules (i.e., all travelers at the first 
starport in their itinerary, all starships poised to enter the 
first starport in the list of starports).
<p>

<p>
<li> You must use synchronization (i.e., Ruby monitors)
to avoid data races and ensure your simulation is valid.  
You must use conditional variables to ensure your simulation
uses synchronization efficiently. 
<p>

<li> Initially you may use a 
single monitor and conditional variable for the entire 
simulation. For a more efficient implementation you should 
have a separate monitor for each starport, and multiple 
conditional variables for each monitor.
<p>

<li>Each starship should sleep for 0.001 seconds after docking at
a starport (by calling "sleep 0.001"). Each traveler should sleep 
for 0.001 seconds after departing a starship.
The thread should release any locks it has acquired before
calling sleep. 
<p>

<li>The simulation ends when all travelers have arrived at their final
starport.  To determine when this condition is reached, each traveler
thread should exit when its traveler reaches its final starport,
and the main thread can call <tt>join</tt> on all the traveler threads.
Notice that it is legal if starship threads continue running for a while 
even after all passengers have reached their final destinations, since 
the join is not instantaneous.  
<p>

<li>You should set <tt>Thread.abort_on_exception = true</tt> in your
code, to detect errors if any thread throws an exception.  
<p>

<li>
In order to see what's going on during your simulation, your program
must print out various messages as simulation events occur.  
For the simulation output to make sense, you must do the following:
<p>

<ul>
<li>Create a lock (e.g., $printMonitor) that all threads must 
acquire when printing messages for simulation events
<li>Before a thread prints out the message for a simulation event,
acquire both the lock for printing messages, and the lock
preventing data races for the simulation event
<li> Immediately after printing, and before you release 
either locks, call $stdout.flush to flush the simulation
message to standard output.
</ul>
<p>
Your code for printing simulation output may look like the following:
<pre>
  starportMonitor.synchronize { 
    ...starship docks at starport...
    $printMonitor.synchronize { 
      puts "starship docking at starport"
      $stdout.flush
    }
  }
</pre>
Following the rules above should ensure that if you build the simulation
correctly, your simulation output will be valid.  Otherwise, you might
get strange interleavings of output messages that look incorrect even
if your simulation code is actually correct.
<p>
</ul>

When testing your simulator, the submit server tests will be running
a verify program on your simulation output to ensure it follows all 
the simulation rules given in the project description, and that no 
errors are introduced due to data races.
<p>

The submit server tests will ignore any lines output beginning with "%".
<p>

TAs will look at your submitted code to check that you are using
synchronization correctly.
<p>

</body>
</html>


