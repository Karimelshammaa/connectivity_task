# Latest Connectivity Status Visualizer

Latest Connectivity Status Visualizer is an application that creates an interactive network graph that illustrates the latest status of Intouch's devices within each organization and place based on the last updates that have been sent.



## Usage

The application is written in R. To use, make sure to install R using:

`sudo apt install r-base-core`

To run the application, use:

`Rscript latest_status_viewer.R`

The script uses `require( )` to load the packages so that any missing library will get installed before running the script.



## Input

The input to the script is an updated csv with the latest connectivity statuses of the devices, located in the same directory as the script.



## Output

The script creates an HTML file in the same directory called intouch_asset_status.html. 

Within the network graph, organizations are shown in purple and places are shown in blue.

A connected asset is shown in green and a disconnected one is shown in red.

Some assets have modules branching out of them, and the status of these modules are also indicated by green and red.

Hovering over an asset or module displays its name, as well as the date of its last update.

