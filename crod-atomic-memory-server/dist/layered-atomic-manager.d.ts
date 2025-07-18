#!/usr/bin/env node
export declare class LayeredAtomicManager {
    private db;
    constructor();
    private initializeLayers;
    storeBaseAtom(wingPath: string[], atomType: string, tags: string[], initialWeight?: number): Promise<string>;
    addAtomReference(atomId: string, refType: string, refTarget: string, refStrength?: number): Promise<void>;
    storeBatchAtoms(atoms: Array<{
        wingPath: string[];
        atomType: string;
        tags: string[];
        initialWeight?: number;
    }>): Promise<string[]>;
    createContext(atomId: string, contextType: string, adjustedWeight?: number): Promise<string>;
    adjustContext(contextId: string, adjustmentType: string, adjustmentValue: number, reason?: string): Promise<void>;
    createPatternChain(chainName: string, chainType: string, atomIds: string[]): Promise<string>;
    validatePatternChain(chainId: string): Promise<number>;
    refactorPatternChain(chainId: string, refactorType: string): Promise<boolean>;
    queryWithOptimization(query: string, layers?: string[]): Promise<any[]>;
    private getChainState;
    private optimizeChain;
    private mergeRedundantAtoms;
    private reorganizeChain;
    private updateHeatMap;
    close(): void;
}
//# sourceMappingURL=layered-atomic-manager.d.ts.map