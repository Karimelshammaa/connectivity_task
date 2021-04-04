# Loading/Installing required packages
suppressMessages(require(dplyr, quietly = T))
suppressMessages(require(networkD3, quietly = T))
suppressMessages(require(htmlwidgets, quietly = T))
suppressMessages(require(data.table, quietly = T))
suppressMessages(require(readr, quietly = T))

# Loading file
connectivity_df <- connectivity_task <- read_csv("connectivity_task.csv", 
                                                 col_types = cols(
                                                   event_time = col_datetime(
                                                     format = "%Y-%m-%d %H:%M:%S")))

# To create a network graph with the latest status of each asset and module,
# we need to create:
#     1- A nodes df showing the different nodes of the network     
#     2- A links df showing the relationship between the nodes

# ---------------------------------------------------------
# Creating the nodes df

# Creating df to define module nodes with the last update for each one
modules <- connectivity_df %>% 
  filter(!is.na(module_id)) %>% 
  group_by(module_id, asset_name) %>% 
  filter(event_time == max(event_time)) %>% 
  ungroup() %>% 
  mutate(group = ifelse(event_type == 'Connected', 
                        'Connected Device', 
                        'Disconnected Device'),
         size = 1) %>% 
  mutate(name = paste(module_id, ' | ',event_time)) %>% 
  select(name, group, size)


# Creating tmp df with latest update for each event which we then use to create
# the dfs defining the nodes of the assets, organizations and places
tmp <- connectivity_df %>% 
  group_by(asset_name) %>% 
  filter(event_time == max(event_time)) %>% 
  ungroup()

# Defining asset nodes
assets <- tmp %>% 
  distinct(asset_name, .keep_all = T) %>% 
  mutate(group = ifelse(event_type == 'Connected', 
                        'Connected Device', 
                        'Disconnected Device'),
         size = 30) %>% 
  mutate(name = paste(asset_name, ' | ',event_time)) %>% 
  select(name, group, size)

# Defining place nodes
places <- tmp %>% 
  distinct(place_name) %>% 
  mutate(group = 'Place', size = 100) %>% 
  rename(name = place_name)

# Defining organization nodes
organizations <- tmp %>% 
  distinct(organisation_name, .keep_all = T) %>% 
  mutate(group = 'Organization', size = 1000) %>% 
  rename(name = organisation_name) %>% 
  select(name, group, size)

# Concatenating all the nodes and giving them Ids
nodes = bind_rows(assets, places, organizations, modules)
nodes$ID <- seq.int(nrow(nodes)) - 1

# ---------------------------------------------------------
# Creating the links df

# Creating the links between Places and Assets
links_1 <- connectivity_task %>% 
  group_by(asset_name) %>% 
  filter(event_time == max(event_time)) %>% 
  ungroup() %>% 
  left_join(nodes %>% rename(place_name=name), by='place_name') %>%
  rename(source = ID) %>% 
  mutate(asset_name = paste(asset_name, ' | ',event_time)) %>% 
  left_join(nodes %>% rename(asset_name=name), by='asset_name') %>%
  rename(target = ID) %>% 
  select(source, target)

# Creating the links between Organizations and Places
links_2 <- connectivity_task %>% 
  group_by(asset_name) %>% 
  filter(event_time == max(event_time)) %>% 
  ungroup() %>% 
  left_join(nodes %>% rename(organisation_name=name), by='organisation_name') %>%
  rename(source = ID) %>%
  left_join(nodes %>% rename(place_name=name), by='place_name') %>%
  rename(target = ID) %>% 
  select(source, target)

# Creating the links between Assets and Modules
links_3 <- connectivity_task %>% 
  group_by(asset_name) %>% 
  mutate(asset_new_name = paste(asset_name, ' | ', max(event_time))) %>%
  ungroup() %>% 
  left_join(nodes %>% rename(asset_new_name=name), by='asset_new_name') %>%
  rename(target = ID) %>% 
  filter(!is.na(module_id)) %>% 
  group_by(module_id, asset_name) %>% 
  filter(event_time == max(event_time)) %>% 
  mutate(module_id_new = paste(module_id, ' | ',event_time)) %>% 
  ungroup() %>% 
  left_join(nodes %>% rename(module_id_new=name), by='module_id_new') %>%
  rename(source = ID) %>% 
  select(source, target)
  
# Concatenating all the links
links <- bind_rows(links_1, links_2, links_3)


# ---------------------------------------------------------
# Creating the network

# Preparing the nodes and links dfs
nodes = nodes %>% select(name, group, size)
nodes <- as.data.frame(nodes)
links <- as.data.frame(links)

# Setting the colors of the nodes
ColourScale <- 'd3.scaleOrdinal()
            .domain(["Organization", "Place", "Connected Device", "Disconnected Device"])
           .range(["#656BB3", "#1799E9", "#3FC183", "#E55933"]);'

# Creating the Network
p <- forceNetwork(Links = links, 
                  Nodes = nodes, 
                  Source = 'source',
                  Target = 'target',
                  Group = 'group', 
                  NodeID = 'name',
                  Nodesize = 'size',
                  linkDistance = 100,
                  radiusCalculation = JS("Math.sqrt(d.nodesize)+6"),
                  colourScale = JS(ColourScale),
                  legend = T,
                  fontSize = 20,
                  zoom = T) %>% 
  prependContent(htmltools::tags$h1("Latest Connectivity Status"))

# Saving the network to file
saveWidget(p, file=paste0(getwd(), "/intouch_asset_status.html"))
print('HTML file with network graph created in directory')
