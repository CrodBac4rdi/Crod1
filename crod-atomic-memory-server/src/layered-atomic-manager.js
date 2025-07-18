import { promises as fs } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import crypto from 'crypto';

// CROD Layered Atomic Memory - Progressive Disclosure Implementation
const defaultMemoryPath = path.join(path.dirname(fileURLToPath(import.meta.url)), '../dist/crod-layered-memory.json');
const MEMORY_FILE_PATH = process.env.CROD_LAYERED_MEMORY_PATH || defaultMemoryPath;

export class CrodLayeredAtomicManager {
    async loadStructure() {
        try {
            const data = await fs.readFile(MEMORY_FILE_PATH, "utf-8");
            const parsed = JSON.parse(data);
            // Ensure atoms is a Map
            if (Array.isArray(parsed.atoms)) {
                parsed.atoms = new Map(parsed.atoms);
            }
            if (Array.isArray(parsed.atomData)) {
                parsed.atomData = new Map(parsed.atomData);
            }
            return parsed;
        } catch (error) {
            if (error.code === "ENOENT") {
                return this.createInitialStructure();
            }
            throw error;
        }
    }

    createInitialStructure() {
        return {
            wings: {
                'coding': { 
                    id: 'wing_coding', 
                    path: ['coding'], 
                    atomRefs: [], // Only store atom IDs
                    parent: null, 
                    specificity: 0.1,
                    tags: ['programming', 'development']
                },
                'coding_elixir': { 
                    id: 'wing_coding_elixir', 
                    path: ['coding', 'elixir'], 
                    atomRefs: [], 
                    parent: 'coding', 
                    specificity: 0.2,
                    tags: ['elixir', 'functional', 'beam']
                },
                'coding_elixir_phoenix': { 
                    id: 'wing_coding_elixir_phoenix', 
                    path: ['coding', 'elixir', 'phoenix'], 
                    atomRefs: [], 
                    parent: 'coding_elixir', 
                    specificity: 0.3,
                    tags: ['phoenix', 'web', 'framework']
                },
                'semantic': { 
                    id: 'wing_semantic', 
                    path: ['semantic'], 
                    atomRefs: [], 
                    parent: null, 
                    specificity: 0.1,
                    tags: ['knowledge', 'concepts']
                },
                'brain_contexts': { 
                    id: 'wing_brain_contexts', 
                    path: ['brain', 'contexts'], 
                    atomRefs: [], 
                    parent: null, 
                    specificity: 0.2,
                    tags: ['ai', 'consciousness', 'neural']
                }
            },
            atoms: new Map(), // Meta information only
            atomData: new Map(), // Full atom data, accessed separately
            links: new Map(), // Links between atoms
            trinity: { ich: 2, bins: 3, wieder: 5 },
            consciousness: {
                level: 0.172,
                activationHistory: [],
                neuralActivity: 0.05,
                patternDensity: 0.004,
                timeDecay: 1.0
            },
            stats: {
                totalAtoms: 0,
                totalWings: 5,
                totalLinks: 0,
                lastAccess: Date.now()
            }
        };
    }

    async saveStructure(structure) {
        const serializable = {
            ...structure,
            atoms: Array.from(structure.atoms.entries()),
            atomData: Array.from(structure.atomData.entries()),
            links: Array.from(structure.links.entries())
        };
        await fs.writeFile(MEMORY_FILE_PATH, JSON.stringify(serializable, null, 2));
    }

    // Store atom with layered approach
    async storeLayeredAtom(wingPath, atomData, atomType = 'fact') {
        const structure = await this.loadStructure();
        
        const wingKey = wingPath.join('_');
        const atomId = crypto.randomUUID();
        const atomHash = crypto.createHash('sha256')
            .update(JSON.stringify({wingPath, atomData}))
            .digest('hex');
        
        // Create wing if doesn't exist
        if (!structure.wings[wingKey]) {
            structure.wings[wingKey] = {
                id: `wing_${wingKey}`,
                path: wingPath,
                atomRefs: [],
                parent: wingPath.length > 1 ? wingPath.slice(0, -1).join('_') : null,
                specificity: wingPath.length * 0.1,
                tags: []
            };
            structure.stats.totalWings++;
        }

        // Extract meta information
        const metaInfo = this.extractMetaInfo(atomData);
        
        // Store meta information in atoms Map
        structure.atoms.set(atomId, {
            id: atomId,
            hash: atomHash,
            type: atomType,
            wingPath: wingPath,
            wingId: structure.wings[wingKey].id,
            summary: metaInfo.summary,
            tags: metaInfo.tags,
            relatedAtoms: [], // Will be populated by link system
            size: JSON.stringify(atomData).length,
            created: Date.now(),
            accessed: Date.now(),
            heat: 1.0 // Initial heat
        });

        // Store full data separately
        structure.atomData.set(atomId, atomData);

        // Add atom reference to wing
        structure.wings[wingKey].atomRefs.push(atomId);
        
        // Update stats
        structure.stats.totalAtoms++;
        structure.stats.lastAccess = Date.now();

        await this.saveStructure(structure);
        
        return { 
            atomId, 
            wingPath,
            summary: metaInfo.summary,
            tags: metaInfo.tags
        };
    }

    // Extract meta information from atom data
    extractMetaInfo(atomData) {
        let summary = '';
        let tags = [];

        if (typeof atomData === 'string') {
            summary = atomData.substring(0, 100) + (atomData.length > 100 ? '...' : '');
            // Extract potential tags from content
            tags = this.extractTags(atomData);
        } else if (typeof atomData === 'object') {
            summary = atomData.title || atomData.name || atomData.summary || 
                      JSON.stringify(atomData).substring(0, 100) + '...';
            tags = atomData.tags || this.extractTags(JSON.stringify(atomData));
        }

        return { summary, tags };
    }

    // Extract tags from content
    extractTags(content) {
        const tags = new Set();
        
        // Common programming keywords
        const keywords = ['function', 'class', 'module', 'interface', 'async', 
                         'elixir', 'phoenix', 'javascript', 'docker', 'memory',
                         'crod', 'neural', 'pattern', 'consciousness'];
        
        const lowerContent = content.toLowerCase();
        keywords.forEach(keyword => {
            if (lowerContent.includes(keyword)) {
                tags.add(keyword);
            }
        });

        return Array.from(tags);
    }

    // Progressive search - returns only meta information
    async searchLayered(query, options = {}) {
        const {
            wingPaths = null,
            limit = 20,
            includeRelated = false,
            minRelevance = 0.3
        } = options;

        const structure = await this.loadStructure();
        const results = [];
        const queryLower = query.toLowerCase();
        const queryTags = this.extractTags(query);

        // Search through atoms meta information
        for (const [atomId, atomMeta] of structure.atoms) {
            // Skip if wing filter applied
            if (wingPaths && !wingPaths.some(wp => 
                JSON.stringify(atomMeta.wingPath) === JSON.stringify(wp))) {
                continue;
            }

            // Calculate relevance based on meta information only
            let relevance = 0;

            // Check summary match
            if (atomMeta.summary.toLowerCase().includes(queryLower)) {
                relevance += 0.5;
            }

            // Check tag matches
            const tagMatches = atomMeta.tags.filter(tag => 
                queryTags.includes(tag) || tag.includes(queryLower)
            ).length;
            relevance += tagMatches * 0.2;

            // Wing specificity bonus
            relevance += atomMeta.wingPath.length * 0.05;

            // Heat bonus (frequently accessed)
            relevance += atomMeta.heat * 0.1;

            if (relevance >= minRelevance) {
                results.push({
                    atomId,
                    wingPath: atomMeta.wingPath,
                    summary: atomMeta.summary,
                    tags: atomMeta.tags,
                    relevance,
                    relatedCount: atomMeta.relatedAtoms.length,
                    size: atomMeta.size,
                    // Don't include full data - must be fetched separately
                });
            }
        }

        // Sort by relevance and limit
        results.sort((a, b) => b.relevance - a.relevance);
        const limited = results.slice(0, limit);

        // If includeRelated, add first level of related atoms (meta only)
        if (includeRelated) {
            for (const result of limited) {
                const atomMeta = structure.atoms.get(result.atomId);
                result.related = atomMeta.relatedAtoms.slice(0, 3).map(relId => {
                    const relMeta = structure.atoms.get(relId);
                    return {
                        atomId: relId,
                        summary: relMeta.summary,
                        tags: relMeta.tags
                    };
                });
            }
        }

        return {
            query,
            resultCount: limited.length,
            totalMatches: results.length,
            results: limited
        };
    }

    // Get specific atom data (second layer access)
    async getAtomData(atomId) {
        const structure = await this.loadStructure();
        
        const atomMeta = structure.atoms.get(atomId);
        if (!atomMeta) {
            throw new Error(`Atom ${atomId} not found`);
        }

        const atomData = structure.atomData.get(atomId);
        
        // Update access time and heat
        atomMeta.accessed = Date.now();
        atomMeta.heat = Math.min(atomMeta.heat * 1.1, 10); // Increase heat
        
        await this.saveStructure(structure);

        return {
            meta: atomMeta,
            data: atomData
        };
    }

    // Get wing structure (navigation layer)
    async getWingStructure(wingPath = null) {
        const structure = await this.loadStructure();
        
        if (!wingPath) {
            // Return top-level wing summary
            const wings = Object.values(structure.wings)
                .filter(w => !w.parent)
                .map(w => ({
                    id: w.id,
                    path: w.path,
                    atomCount: w.atomRefs.length,
                    tags: w.tags,
                    children: Object.values(structure.wings)
                        .filter(child => child.parent === w.id)
                        .map(c => ({ id: c.id, path: c.path }))
                }));
            
            return { wings };
        }

        // Return specific wing details
        const wingKey = wingPath.join('_');
        const wing = structure.wings[wingKey];
        
        if (!wing) {
            throw new Error(`Wing ${wingKey} not found`);
        }

        // Get atom summaries for this wing
        const atomSummaries = wing.atomRefs.slice(0, 10).map(atomId => {
            const atomMeta = structure.atoms.get(atomId);
            return {
                atomId,
                summary: atomMeta.summary,
                tags: atomMeta.tags,
                heat: atomMeta.heat
            };
        });

        return {
            wing: {
                ...wing,
                atomCount: wing.atomRefs.length,
                recentAtoms: atomSummaries
            }
        };
    }

    // Create links between atoms
    async linkAtoms(fromAtomId, toAtomId, linkType = 'related') {
        const structure = await this.loadStructure();
        
        const linkId = `${fromAtomId}-${toAtomId}`;
        
        structure.links.set(linkId, {
            from: fromAtomId,
            to: toAtomId,
            type: linkType,
            strength: 1.0,
            created: Date.now()
        });

        // Update atom meta to include relation
        const fromMeta = structure.atoms.get(fromAtomId);
        const toMeta = structure.atoms.get(toAtomId);
        
        if (fromMeta && toMeta) {
            if (!fromMeta.relatedAtoms.includes(toAtomId)) {
                fromMeta.relatedAtoms.push(toAtomId);
            }
            if (!toMeta.relatedAtoms.includes(fromAtomId)) {
                toMeta.relatedAtoms.push(fromAtomId);
            }
        }

        structure.stats.totalLinks++;
        await this.saveStructure(structure);
        
        return { linkId, message: 'Atoms linked successfully' };
    }

    // Get deep context by following links
    async getDeepContext(atomId, depth = 2) {
        const structure = await this.loadStructure();
        const visited = new Set();
        const context = [];

        const traverse = (currentId, currentDepth) => {
            if (currentDepth === 0 || visited.has(currentId)) return;
            
            visited.add(currentId);
            const atomMeta = structure.atoms.get(currentId);
            
            if (!atomMeta) return;

            context.push({
                atomId: currentId,
                depth: depth - currentDepth,
                summary: atomMeta.summary,
                tags: atomMeta.tags,
                wingPath: atomMeta.wingPath
            });

            // Follow relations
            atomMeta.relatedAtoms.forEach(relId => {
                traverse(relId, currentDepth - 1);
            });
        };

        traverse(atomId, depth);
        
        return {
            rootAtom: atomId,
            contextDepth: depth,
            atoms: context
        };
    }
}