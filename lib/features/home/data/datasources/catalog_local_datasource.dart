import '../../domain/entities/catalog_entities.dart';

class CatalogLocalDataSource {
  List<Category> getCategories() {
    return const [
      Category(
        id: 'cat_decor',
        name: 'Decor & Styling',
        slug: 'decor-styling',
        subCategories: [
          SubCategory(id: 'sub_floral', name: 'Floral & Mandap'),
          SubCategory(id: 'sub_balloon', name: 'Balloon & Theme Decor'),
        ],
      ),
      Category(
        id: 'cat_sound',
        name: 'Sound & DJ',
        slug: 'sound-dj',
        subCategories: [
          SubCategory(id: 'sub_dj', name: 'Live DJ & Lights'),
          SubCategory(id: 'sub_acoustics', name: 'Acoustic Bands'),
        ],
      ),
      Category(
        id: 'cat_catering',
        name: 'Catering & Dining',
        slug: 'catering-dining',
        subCategories: [
          SubCategory(id: 'sub_buffet', name: 'Royal Buffet'),
          SubCategory(id: 'sub_live_counters', name: 'Live Food Counters'),
        ],
      ),
      Category(
        id: 'cat_photo',
        name: 'Photography & Film',
        slug: 'photography-film',
        subCategories: [
          SubCategory(id: 'sub_cinematic', name: 'Cinematic Video'),
          SubCategory(id: 'sub_drone', name: 'Drone Aerial Shoots'),
        ],
      ),
      Category(
        id: 'cat_venue',
        name: 'Venues & Banquets',
        slug: 'venues-banquets',
        subCategories: [
          SubCategory(id: 'sub_lawn', name: 'Open Lawns'),
          SubCategory(id: 'sub_hall', name: 'Luxury Banquet Halls'),
        ],
      ),
      Category(
        id: 'cat_planner',
        name: 'Full Event Planners',
        slug: 'full-event-planners',
        subCategories: [
          SubCategory(id: 'sub_wedding', name: 'End-to-End Weddings'),
          SubCategory(id: 'sub_corporate', name: 'Corporate Summits'),
        ],
      ),
    ];
  }

  List<EventPackage> getPackages() {
    return const [
      EventPackage(
        id: 'pkg_royal_wedding',
        name: 'Royal Heritage Wedding Extravaganza',
        slug: 'royal-heritage-wedding',
        coverImageUrl:
            'https://images.unsplash.com/photo-1519741497674-611481863552?w=800&auto=format&fit=crop',
        galleryImages: [
          'https://images.unsplash.com/photo-1519741497674-611481863552?w=800&auto=format&fit=crop',
          'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?w=800&auto=format&fit=crop',
        ],
        description:
            'Comprehensive 3-day royal Indian wedding package featuring custom floral mandap, celebrity DJ setup, 7-course multi-cuisine catering, and cinematic drone coverage.',
        priceInPaise: 85000000,
        advanceDepositFlat: 15000000,
        capacityMin: 200,
        capacityMax: 1500,
        organizer: OrganizerSummary(
          id: 'org_aurora',
          businessName: 'Aurora Royal Planners',
          displayName: 'Aurora Events Pvt Ltd',
          city: 'Mumbai',
          rating: 4.9,
          avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
        ),
        lineItems: [
          LineItem(title: 'Grand Floral Mandap & Stage (Hydraulic)', quantity: 1),
          LineItem(title: '7-Course Royal Buffet (Veg + Non-Veg, 500 Guests)', quantity: 500),
          LineItem(title: '4K Cinematic Wedding Film + Drone Coverage', quantity: 1),
          LineItem(title: 'Concert Grade JBL Line Array Sound + Laser Show', quantity: 1),
        ],
        cancellationPolicy:
            '100% refund up to 30 days before event. 50% refund up to 14 days.',
      ),
      EventPackage(
        id: 'pkg_corporate_summit',
        name: 'Tech Horizon Global Summit Suite',
        slug: 'tech-horizon-summit',
        coverImageUrl:
            'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800&auto=format&fit=crop',
        description:
            'Turnkey corporate conference & keynote setup with dual LED walls, broadcast audio recording, live streaming uplink, and VIP networking lounge catering.',
        priceInPaise: 38000000,
        advanceDepositFlat: 8000000,
        capacityMin: 50,
        capacityMax: 600,
        organizer: OrganizerSummary(
          id: 'org_nexus',
          businessName: 'Nexus Corporate Productions',
          city: 'Bengaluru',
          rating: 4.85,
        ),
        lineItems: [
          LineItem(title: 'P2.5 Curved Ultra HD LED Screen (30x10ft)', quantity: 1),
          LineItem(title: 'Multi-Cam 4K Live Broadcast Switching', quantity: 1),
          LineItem(title: 'Gourmet High-Tea & Corporate Lunch Box Catering', quantity: 200),
        ],
      ),
      EventPackage(
        id: 'pkg_neon_night',
        name: 'Electric Pulse Neon DJ Concert',
        slug: 'electric-pulse-concert',
        coverImageUrl:
            'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=800&auto=format&fit=crop',
        description:
            'Festival-grade festival and birthday bash experience. CO2 jets, cold pyrotechnics, synchronized RGB beam arrays, and top-tier EDM DJ artists.',
        priceInPaise: 18000000,
        advanceDepositFlat: 4500000,
        capacityMin: 80,
        capacityMax: 800,
        organizer: OrganizerSummary(
          id: 'org_sonic',
          businessName: 'Sonic Boom Entertainment',
          city: 'Mumbai',
          rating: 4.92,
        ),
      ),
    ];
  }

  List<StandaloneService> getServices() {
    return const [
      StandaloneService(
        id: 'srv_cinematic_photo',
        name: 'Cinematic 4K Candid Photography & Teaser',
        description:
            '2 Senior photographers, candid + traditional, 300+ edited high-res digital shots delivered in 48 hours.',
        coverImageUrl:
            'https://images.unsplash.com/photo-1537633552985-df8429e8048b?w=800&auto=format&fit=crop',
        priceInPaise: 4500000,
        advanceDepositFlat: 1500000,
        pricingUnit: PricingUnit.FIXED,
        organizer: OrganizerSummary(
          id: 'org_lens',
          businessName: 'Lumina Lens Studios',
          city: 'Mumbai',
          rating: 4.95,
        ),
      ),
      StandaloneService(
        id: 'srv_gourmet_live_counter',
        name: 'Gourmet Wood-Fired Pizza & Pasta Station',
        description:
            'Artisan Italian live counter with chef on-site. Unlimited handcrafted thin-crust pizzas & artisanal pastas.',
        coverImageUrl:
            'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800&auto=format&fit=crop',
        priceInPaise: 85000,
        advanceDepositFlat: 20000,
        pricingUnit: PricingUnit.PER_HEAD,
        organizer: OrganizerSummary(
          id: 'org_gusto',
          businessName: 'Gusto Culinary Atelier',
          city: 'Mumbai',
          rating: 4.88,
        ),
      ),
      StandaloneService(
        id: 'srv_laser_light_show',
        name: 'Club Grade Moving Beam & Laser FX',
        description:
            '8x 350W Beam Moving Heads, 2x 10W RGB Animation Lasers with DMX programmed synchronization.',
        coverImageUrl:
            'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=800&auto=format&fit=crop',
        priceInPaise: 2500000,
        advanceDepositFlat: 800000,
        pricingUnit: PricingUnit.FIXED,
        organizer: OrganizerSummary(
          id: 'org_sonic',
          businessName: 'Sonic Boom Entertainment',
          city: 'Mumbai',
          rating: 4.92,
        ),
      ),
    ];
  }

  List<PublicEvent> getEvents() {
    final now = DateTime.now();
    return [
      PublicEvent(
        id: 'evt_tech_fest_2026',
        title: 'Sunburn Arena: Neon Horizons',
        slug: 'sunburn-arena-neon-horizons',
        description:
            'Asia’s biggest electronic dance music experience featuring world-renowned international DJs, mind-bending visual mapping, and immersive soundscapes.',
        coverImageUrl:
            'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=800&auto=format&fit=crop',
        categoryId: 'cat_sound',
        mode: EventMode.OFFLINE,
        approvalMode: ApprovalMode.INSTANT,
        venueName: 'Mahalaxmi Racecourse Arena',
        venueAddress: 'Dr. E Moses Rd, Mahalakshmi',
        venueCity: 'Mumbai',
        startDatetime: now.add(const Duration(days: 5, hours: 18)),
        endDatetime: now.add(const Duration(days: 5, hours: 23, minutes: 30)),
        maxCapacity: 5000,
        minPricePaise: 149900,
        maxPricePaise: 899900,
        hostName: 'Sunburn Festival Official',
        ticketTypes: const [
          TicketType(
            id: 'tkt_ga',
            name: 'General Access Phase 1',
            priceInPaise: 149900,
            quantity: 3000,
            soldCount: 1420,
          ),
          TicketType(
            id: 'tkt_vip',
            name: 'VIP Elevated Deck + 2 Drinks',
            priceInPaise: 499900,
            quantity: 800,
            soldCount: 650,
          ),
          TicketType(
            id: 'tkt_backstage',
            name: 'Exclusive Backstage Access Pass',
            priceInPaise: 899900,
            quantity: 100,
            soldCount: 88,
          ),
        ],
      ),
      PublicEvent(
        id: 'evt_design_summit',
        title: 'Figma & AI Design Conclave 2026',
        slug: 'figma-ai-design-conclave',
        description:
            'Masterclasses and networking sessions on modern agentic workflows, design systems, and generative motion graphics with top Silicon Valley product designers.',
        coverImageUrl:
            'https://images.unsplash.com/photo-1531482615713-2afd69097998?w=800&auto=format&fit=crop',
        categoryId: 'cat_planner',
        mode: EventMode.ONLINE,
        approvalMode: ApprovalMode.APPROVAL_REQUIRED,
        meetingUrl: 'https://meet.eventsphere.io/room/design-2026-xyz',
        startDatetime: now.add(const Duration(days: 12, hours: 10)),
        endDatetime: now.add(const Duration(days: 12, hours: 17)),
        maxCapacity: 1200,
        minPricePaise: 0,
        maxPricePaise: 299900,
        hostName: 'Design Systems Guild',
        ticketTypes: const [
          TicketType(
            id: 'tkt_community',
            name: 'Community Pass (Free / Approved)',
            priceInPaise: 0,
            quantity: 800,
            soldCount: 710,
          ),
          TicketType(
            id: 'tkt_pro',
            name: 'Pro Pass + Workshop Recording Access',
            priceInPaise: 299900,
            quantity: 400,
            soldCount: 230,
          ),
        ],
      ),
    ];
  }
}
